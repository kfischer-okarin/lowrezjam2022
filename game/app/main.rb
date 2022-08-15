require 'lib/animations.rb'
require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'

require 'app/camera.rb'
require 'app/colors.rb'
require 'app/fire_particle.rb'
require 'app/hotmap.rb'
require 'app/input_actions.rb'
require 'app/movement.rb'
require 'app/player.rb'
require 'app/slime.rb'
require 'app/resources.rb'

SCREEN_W = 64
SCREEN_H = 64

STAGE_W = 246
STAGE_H = 90

PLAYER_RUN_SPEED = 1
PLAYER_FIRING_SLOWDOWN = 0.4
PLAYER_JUMP_SPEED = 2.2
PLAYER_JUMP_ACCELERATION = 0.08
FIRE_PARTICLE_INITIAL_SPEED = 1.8
HOTMAP_TILE_SIZE = 4
PLAYER_HURT_SPEED_X = 3
PLAYER_HURT_SPEED_Y = 3

SLIME_HURT_SPEED_X = 3

GRAVITY = 0.15
MAX_FALL_VELOCITY = 2

CAMERA_FOLLOW_X_OFFSET = {
  right: -20,
  left: -44
}.freeze
CAMERA_FOLLOW_Y_OFFSET = -5
CAMERA_MIN_X = 0
CAMERA_MAX_X = STAGE_W - SCREEN_W
CAMERA_MIN_Y = -5
CAMERA_MAX_Y = STAGE_H - SCREEN_H
MAX_SCREEN_SHAKE = 10
SCREEN_SHAKE_DECAY = 0.01

INVINCIBLE_TICKS_AFTER_DAMAGE = 120

def tick(args)
  state = args.state
  setup(args) if args.tick_count.zero?
  send(:"#{state.scene}_tick", args)
  state.ticks_in_scene += 1
end

def setup(args)
  state = args.state
  change_to_scene state, :game
  state.ticks_in_scene = 0
end

def change_to_scene(state, scene)
  state.scene = scene
  state.ticks_in_scene = -1
end

def game_tick(args)
  state = args.state
  game_setup(args) if state.ticks_in_scene.zero?
  state.input_actions = InputActions.process_inputs(args.inputs)
  game_update(state)
  render_lowrez(args.outputs) do |screen|
    game_render(state, screen, args.audio)
  end
end

def lose_tick(args)
  state = args.state
  if any_key?(args.inputs)
    change_to_scene state, :game
  end

  render_lowrez(args.outputs) do |screen|
    ['You lose!', 'Press any', 'key to', 'retry...'].each_with_index do |text, index|
      screen.primitives << {
        x: 32, y: 48 - 12 * index, text: text, alignment_enum: 1, vertical_alignment_enum: 1, size_enum: -6,
        font: 'resources/vector.ttf', r: 255, g: 255, b: 255
      }.label!
    end
  end
end

def any_key?(inputs)
  inputs.keyboard.key_down.truthy_keys.length > 0 || inputs.controller_one.key_down.truthy_keys.length > 0
end

def game_setup(args)
  state = args.state
  state.camera = Camera.build

  state.player = Player.build
  state.player[:position][:x] = 20
  Movement.update_collider state.player
  Camera.follow_player! state.camera, state.player, immediately: true
  state.rendered_player = build_render_state load_animations('character')

  # Use render target one time to avoid checkerboard artifacts on first render
  white_sprite(args.outputs, state.rendered_player[:sprite], :blinking_player)

  state.slime = Slime.build
  state.slime[:position][:x] = STAGE_W - 20
  Movement.update_collider state.slime
  state.rendered_slime = build_render_state load_animations('slime')

  state.fans = [
    { x: 12, y: 60 },
    { x: STAGE_W.idiv(2) - 9, y: 60 },
    { x: STAGE_W - 12 - 18, y: 60 },
  ].map { |position|
    build_render_state(load_animations('fan')).tap { |rendered_fan|
      rendered_fan[:position] = position
      rendered_fan[:next_animation] = :fan_rotation
    }
  }

  state.colliders = get_stage_bounds + load_colliders
  state.dangers = [state.slime]

  state.hotmap = Hotmap.build
  state.fire_particles = []
  state.additional_sprite_animations = []
  state.ui_running_animations = []
  state.animations = {
    health_down: Animations.build(
      tile_x: 0, tile_y: 0, tile_w: 8, tile_h: 3, w: 8,
      frames: [
        { duration: 30 },
        *([7, 6, 5, 4, 3, 2, 1].map { |w| { w: w, tile_w: w, duration: 4 } })
      ]
    ),
    invincible_blink: Animations.build(
      frames: [
        { a: 0, duration: 2 },
        { a: 255, duration: 2 }
      ] * INVINCIBLE_TICKS_AFTER_DAMAGE.idiv(4)
    )
  }

  audio = args.audio
  audio[:fire] = {
    input: 'resources/fire.wav',
    looping: true,
    paused: true
  }
  audio[:background] = {
    input: 'resources/machine_rotation.ogg',
    looping: true,
    gain: 0
  }
end

def build_render_state(animations)
  {
    animations: animations,
    sprite: {}.sprite!,
    animation: nil,
    next_animation: nil,
    animation_state: nil
  }
end

def get_stage_bounds
  [
    { collider: { x: 0, y: -5, w: STAGE_W, h: 5 } },
    { collider: { x: 0, y: STAGE_H - 10, w: STAGE_W, h: 5 } },
    { collider: { x: 0, y: 0, w: 5, h: STAGE_H - 10 } },
    { collider: { x: STAGE_W - 5, y: 0, w: 5, h: STAGE_H - 10 } }
  ]
end

def load_colliders
  stage_data = Animations::AsespriteJson.deep_symbolize_keys! $gtk.parse_json_file('resources/stage.ldtk')
  level = stage_data[:levels][0]
  wall_layer_uid = stage_data[:defs][:layers].find { |layer| layer[:identifier] == 'Walls' }[:uid]
  collider_layer = level[:layerInstances].find { |layer| layer[:layerDefUid] == wall_layer_uid }
  grid = collider_layer[:intGridCsv]
  [].tap { |result|
    tiles_per_row = STAGE_W.idiv(6)
    tiles_per_col = STAGE_H.idiv(6)
    grid.each_slice(tiles_per_row).reverse_each.each_with_index do |row, tile_y|
      next if tile_y.zero? || tile_y == tiles_per_col - 1

      row.each_with_index do |cell, tile_x|
        next if cell.zero? || tile_x.zero? || tile_x == tiles_per_row - 1

        x = tile_x * 6
        y = (tile_y * 6) - 5

        neighboring_collider = result.find { |collider|
          collider[:collider][:y] == y && collider[:collider].right == x
        }

        if neighboring_collider
          neighboring_collider[:collider][:w] += 6
        else
          result << { collider: { x: x, y: y, w: 6, h: 5 } }
        end
      end
    end
  }
end

def load_animations(type)
  Animations::AsespriteJson.read("resources/#{type}.json").tap { |animations|
    right_animations = animations.keys.select { |key|
      key.to_s.end_with?('_right')
    }

    right_animations.each do |key|
      left_key = key.to_s.sub('_right', '_left').to_sym
      animations[left_key] = Animations::AsespriteJson.flipped_horizontally animations[key]
    end
  }
end

def game_render(state, outputs, audio)
  outputs.background_color = [0x22, 0x20, 0x34]

  player = state.player
  camera = state.camera

  if player[:health][:ticks_since_hurt].zero?
    camera[:shake][:trauma] += 0.2
    audio[:hurt] = {
      input: 'resources/hurt.wav'
    }
    state.additional_sprite_animations << {
      sprite: state.rendered_player[:sprite],
      animation_state: Animations.start!(
        state.rendered_player[:sprite],
        animation: state.animations[:invincible_blink],
        repeat: false
      )
    }
  end
  Camera.update_shake! state.camera

  stage_sprite = { x: 0, y: -5, w: STAGE_W, h: STAGE_H, path: 'resources/stage/png/Level_0.png' }.sprite!
  Camera.apply! camera, stage_sprite
  outputs.primitives << stage_sprite

  state.fans.each do |fan|
    fan_sprite = fan[:sprite]
    fan_sprite.merge! fan[:position]
    update_animation fan
    Camera.apply! camera, fan_sprite
    outputs.primitives << fan_sprite
  end

  Slime.update_rendered_state! state.slime, state.rendered_slime
  Camera.apply! camera, state.rendered_slime[:sprite]
  outputs.primitives << state.rendered_slime[:sprite]

  Player.update_rendered_state! player, state.rendered_player
  player_sprite = state.rendered_player[:sprite]
  player_sprite = white_sprite(outputs, player_sprite, :blinking_player) if player[:health][:ticks_since_hurt] < 10
  Camera.apply! camera, player_sprite
  outputs.primitives << player_sprite

  state.fire_particles.each do |particle|
    particle.merge! particle[:position]
    Camera.apply! camera, particle
  end
  # Smoothly fade in the background music
  audio[:background][:gain] += 0.01 if audio[:background][:gain] < 1
  # OGG file does not loop cleanly so manual loop
  audio[:background][:playtime] = 1 if (audio[:background][:playtime] || 0) >= 13.5
  audio[:fire][:paused] = !player[:firing]

  outputs.primitives << state.fire_particles

  update_one_time_animations(outputs, state.additional_sprite_animations)

  if $debug.debug_mode?
    render_colliders(outputs, camera, state)
    render_hotmap(outputs, camera, state)
  end

  render_ui(outputs, state)
  update_one_time_animations(outputs, state.ui_running_animations)
  state.ui_running_animations.each do |animation|
    outputs.primitives << animation[:sprite]
  end
end

def render_lowrez(outputs)
  screen = outputs[:screen]
  screen.background_color = [0, 0, 0]
  screen.width = SCREEN_W
  screen.height = SCREEN_H
  yield screen
  outputs.background_color = [0, 0, 0]
  outputs.primitives << { x: 288, y: 8, w: 704, h: 704, path: :screen }.sprite!
end

def update_animation(render_state)
  next_animation = render_state[:next_animation]
  if render_state[:animation_type] == next_animation
    Animations.next_tick render_state[:animation_state]
    Animations.apply! render_state[:sprite], animation_state: render_state[:animation_state]
  else
    render_state[:animation_type] = next_animation
    render_state[:animation_state] = Animations.start!(
      render_state[:sprite],
      animation: render_state[:animations][next_animation]
    )
  end
end

def render_colliders(outputs, camera, state)
  render_collider outputs, camera, state.player
  render_collider outputs, camera, state.slime
  state.colliders.each do |collider|
    render_collider outputs, camera, collider
  end
end

def render_collider(outputs, camera, entity)
  rect = entity[:collider].to_border r: 255, g: 0, b: 0
  Camera.apply! camera, rect
  outputs.primitives << rect
end

def render_hotmap(outputs, camera, state)
  state.hotmap.each do |x, y_values|
    y_values.each_key do |y|
      rect = {
        x: x * HOTMAP_TILE_SIZE, y: y * HOTMAP_TILE_SIZE, w: HOTMAP_TILE_SIZE, h: HOTMAP_TILE_SIZE
      }.to_border r: 255, g: 255, b: 255
      Camera.apply! camera, rect
      outputs.primitives << rect
    end
  end
end

def render_ui(outputs, state)
  player = state.player
  outputs.primitives << { x: 0, y: SCREEN_H - 5, w: SCREEN_W, h: 5, r: 0, g: 0, b: 0 }.solid!
  health = player[:health]
  outputs.primitives << health[:max].times.map { |i|
    health_bar_sprite(i).merge!(
      health[:current] > i ? Colors::DawnBringer32::BRIGHT_RED : Colors::DawnBringer32::DARK_BROWN
    )
  }
  return unless health[:ticks_since_hurt].zero?

  state.ui_running_animations << {
    sprite: health_bar_sprite(health[:current]).merge!(Colors::DawnBringer32::WHITE),
    animation_state: Animations.start!({}, animation: state.animations[:health_down], repeat: false)
  }
end

def update_one_time_animations(outputs, running_animations)
  running_animations.each do |running_animation|
    Animations.next_tick running_animation[:animation_state]
    Animations.apply! running_animation[:sprite], animation_state: running_animation[:animation_state]
  end

  running_animations.reject! { |running_animation|
    Animations.finished? running_animation[:animation_state]
  }
end

def health_bar_sprite(hp_index)
  {
    x: 1 + (hp_index * 7), y: SCREEN_H - 4, w: 8, h: 3,
    path: 'resources/health.png'
  }.sprite!
end

def white_sprite(outputs, sprite, render_target_name)
  # Prepare render target in sprite size
  render_target = outputs[render_target_name]
  render_target.width = sprite[:w]
  render_target.height = sprite[:h]

  # Render sprite at bottom left of render target
  render_target.primitives << sprite.merge(x: 0, y: 0)
  # Additive overlay with white rectangle to create a white sprite
  render_target.primitives << sprite.to_solid(x: 0, y: 0, r: 255, g: 255, b: 255, blendmode_enum: 2)

  # Return render target as sprite
  { x: sprite[:x], y: sprite[:y], w: sprite[:w], h: sprite[:h], path: render_target_name }.sprite!
end

def game_update(state)
  player = state.player
  Player.update!(player, state)
  handle_firethrower(state)
  Camera.follow_player! state.camera, player
  Slime.update! state.slime, state
  handle_game_end(state)
end

def handle_firethrower(state)
  player = state.player
  fire_particles = state.fire_particles

  fire_particles.reject! { |particle| particle[:state] == :gone }

  fire_particles.each do |particle|
    FireParticle.update! particle
  end

  Hotmap.update! state.hotmap, fire_particles

  return unless player[:firing]

  x_offset = player[:face_direction] == :left ? -7 : 7
  2.times do |i|
    fire_particles << FireParticle.build(
      x: player[:position][:x] + x_offset,
      y: player[:position][:y] + 9 - i,
      direction: player[:face_direction]
    )
  end
end

def handle_game_end(state)
  if state.player[:health][:current] <= 0
    change_to_scene state, :lose
  end
end

$gtk.reset
