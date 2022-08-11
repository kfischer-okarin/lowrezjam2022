require 'lib/animations.rb'
require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'

require 'app/camera.rb'
require 'app/colors.rb'
require 'app/fire_particle.rb'
require 'app/input_actions.rb'
require 'app/movement.rb'
require 'app/player.rb'
require 'app/resources.rb'

SCREEN_W = 64
SCREEN_H = 64

STAGE_W = 240
STAGE_H = 120

PLAYER_RUN_SPEED = 1
PLAYER_FIRING_SLOWDOWN = 0.4
PLAYER_JUMP_SPEED = 2.2
PLAYER_JUMP_ACCELERATION = 0.08
FIRE_PARTICLE_INITIAL_SPEED = 1.8

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
CAMERA_MAX_Y = STAGE_H - SCREEN_H - 5

def tick(args)
  state = args.state
  setup(state) if args.tick_count.zero?
  render(state, args.outputs)
  state.input_actions = InputActions.process_inputs(args.inputs)
  update(state)
end

def setup(state)
  state.camera = Camera.build
  state.player = Player.build
  state.player[:position][:x] = 20
  Camera.follow_player! state.camera, state.player, immediately: true
  state.rendered_player = build_render_state load_animations('character')
  state.rendered_slime = build_render_state load_animations('slime')
  state.colliders = get_stage_bounds + load_colliders

  state.fire_particles = []
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
    { collider: { x: 0, y: STAGE_H, w: STAGE_W, h: 5 } },
    { collider: { x: 0, y: 0, w: 5, h: STAGE_H } },
    { collider: { x: STAGE_W - 5, y: 0, w: 5, h: STAGE_H } }
  ]
end

def load_colliders
  stage_data = Animations::AsespriteJson.deep_symbolize_keys! $gtk.parse_json_file('resources/stage.ldtk')
  level = stage_data[:levels][0]
  layer = level[:layerInstances][0]
  grid = layer[:intGridCsv]
  [].tap { |result|
    tiles_per_row = STAGE_W.idiv(6)
    tiles_per_col = STAGE_H.idiv(6)
    grid.each_slice(tiles_per_row).reverse_each.each_with_index do |row, tile_y|
      next if tile_y == 0 || tile_y == tiles_per_col - 1

      row.each_with_index do |cell, tile_x|
        next if cell.zero? || tile_x == 0 || tile_x == tiles_per_row - 1

        x = tile_x * 6
        y = tile_y * 6 - 5

        neighboring_collider = result.find { |collider|
          collider[:collider].right == x
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
      animations[left_key] = Animations.flipped_horizontally animations[key]
    end
  }
end

def render(state, outputs)
  screen = outputs[:screen]
  screen.background_color = [0x18, 0x14, 0x25]
  screen.width = SCREEN_W
  screen.height = SCREEN_H

  camera = state.camera

  stage_sprite = { x: 0, y: -5, w: STAGE_W, h: STAGE_H, path: 'resources/stage/png/Level_0.png' }.sprite!
  Camera.apply! camera, stage_sprite
  screen.primitives << stage_sprite

  Player.update_rendered_state! state.player, state.rendered_player
  Camera.apply! camera, state.rendered_player[:sprite]
  screen.primitives << state.rendered_player[:sprite]

  state.fire_particles.each do |particle|
    particle.merge! particle[:position]
    Camera.apply! camera, particle
  end

  screen.primitives << state.fire_particles

  render_colliders(screen, camera, state) if $debug.debug_mode?

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
  state.colliders.each do |collider|
    render_collider outputs, camera, collider
  end
end

def render_collider(outputs, camera, entity)
  rect = entity[:collider].to_border r: 255, g: 0, b: 0
  Camera.apply! camera, rect
  outputs.primitives << rect
end

def update(state)
  player = state.player
  Player.update!(player, state)
  handle_firethrower(player, state.fire_particles)
  Camera.follow_player! state.camera, player
end

def handle_firethrower(player, fire_particles)
  fire_particles.reject! { |particle| particle[:state] == :gone }

  fire_particles.each do |particle|
    FireParticle.update! particle
  end

  return unless player[:firing]

  x_offset = player[:face_direction] == :left ? -9 : 7
  2.times do |i|
    fire_particles << FireParticle.build(
      x: player[:position][:x] + x_offset,
      y: player[:position][:y] + 9 - i,
      direction: player[:face_direction]
    )
  end
end

$gtk.reset
