require 'lib/animations.rb'
require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'

require 'app/camera.rb'
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
  state.rendered_player = {
    animations: load_player_animations,
    sprite: {}.sprite!,
    animation: nil,
    next_animation: nil,
    animation_state: nil
  }
  state.colliders = get_stage_bounds + load_colliders

  state.fire_particles = []
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
  stage_data = Animations.deep_symbolize_keys! $gtk.parse_json_file('resources/stage.ldtk')
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

def load_player_animations
  Animations.read_asesprite_json('resources/character.json').tap { |animations|
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

  state.rendered_player[:sprite][:x] = state.player[:position][:x] - 8
  state.rendered_player[:sprite][:y] = state.player[:position][:y]
  Camera.apply! camera, state.rendered_player[:sprite]

  state.rendered_player[:next_animation] = :"#{state.player[:state]}_#{state.player[:face_direction]}"
  update_animation(state.rendered_player)

  screen.primitives << state.rendered_player[:sprite]

  state.fire_particles.each do |particle|
    particle[:x] = particle[:position][:x]
    particle[:y] = particle[:position][:y]
    Camera.apply! camera, particle
  end

  screen.primitives << state.fire_particles

  outputs.background_color = [0, 0, 0]
  outputs.primitives << { x: 288, y: 8, w: 704, h: 704, path: :screen }.sprite!
  outputs.primitives << { x: 20, y: 720, text: $gtk.current_framerate.to_i.to_s, r: 255, g: 255, b: 255 }.label!
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

def update(state)
  player = state.player
  Player.update!(player, state)
  handle_firethrower(player, state.fire_particles)
  Camera.follow_player! state.camera, player
end

def handle_firethrower(player, fire_particles)
  fire_particles.reject! { |particle| particle[:lifetime] >= 40 }

  fire_particles.each do |particle|
    update_fire_particle particle
  end

  if player[:firing]
    x_offset = player[:face_direction] == :left ? -8 : 7
     2.times do |i|
      fire_particles << {
        position: {
          x: player[:position][:x] + x_offset,
          y: player[:position][:y] + 9 - i
        },
        x: 0,
        y: 0,
        w: 2,
        h: 2,
        path: :pixel,
        r: 255, g: 0, b: 0,
        lifetime: 0,
        movement: { x: 0, y: 0 },
        velocity: {
          x: player[:face_direction] == :left ? -FIRE_PARTICLE_INITIAL_SPEED : FIRE_PARTICLE_INITIAL_SPEED,
          y: 0
        },
        rotation_sign: player[:face_direction] == :left ? -1 : 1
      }.tap { |particle| rotate_particle_velocity_by particle, -0.4 }
    end
  end
end

FIRE_WHITE = 0
FIRE_YELLOW = 5
FIRE_RED = 13
FIRE_DARK_RED = 18
FIRE_SMOKE = 25

def update_fire_particle(particle)
  particle[:movement][:x] += particle[:velocity][:x]
  particle[:movement][:y] += particle[:velocity][:y]
  Movement.move particle, :x
  Movement.move particle, :y

  case particle[:lifetime]
  when FIRE_WHITE
    particle.merge! r: 0xff, g: 0xff, b: 0xff
  when FIRE_YELLOW
    particle[:velocity][:x] *= 0.7
    particle[:velocity][:y] *= 0.7
    particle.merge! r: 0xfb, g: 0xf2, b: 0x36
  when FIRE_RED
    particle[:velocity][:x] *= 0.8
    particle[:velocity][:y] *= 0.8
    particle.merge! r: 0xd9, g: 0x57, b: 0x63
  when FIRE_DARK_RED
    particle[:velocity][:x] *= 0.5
    particle[:velocity][:y] *= 0.5
    particle.merge! r: 0xac, g: 0x32, b: 0x32
  end

  case particle[:lifetime]
  when FIRE_WHITE
    rotate_particle_velocity_by particle, (rand * 0.6 - 0.2)
  when FIRE_YELLOW..FIRE_DARK_RED
    rotate_particle_velocity_by particle, (rand * 0.4 - 0.1)
  when FIRE_DARK_RED..FIRE_SMOKE
    if (!particle[:r] == 0x45 && rand < 0.2) || particle[:lifetime] == FIRE_SMOKE
      particle[:velocity] = { x: 0, y: 0.5 }
      rotate_particle_velocity_by particle, (rand * 0.8 - 0.4)
      particle[:w] = 3
      particle[:h] = 3
      particle.merge! r: 0x45, g: 0x28, b: 0x3c
    end
  end

  particle[:lifetime] += 1
end

def rotate_particle_velocity_by(particle, angle)
  rotate_by particle[:velocity], particle[:rotation_sign] * angle
end

def rotate_by(vector, angle)
  length = Math.sqrt(vector[:x] ** 2 + vector[:y] ** 2)
  new_angle = vector_angle(vector) + angle
  vector[:x] = length * Math.cos(new_angle)
  vector[:y] = length * Math.sin(new_angle)
end

def vector_angle(vector)
  Math.atan2 vector[:y], vector[:x]
end

$gtk.reset
