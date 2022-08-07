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

PLAYER_RUN_SPEED = 1
PLAYER_JUMP_SPEED = 2
PLAYER_JUMP_ACCELERATION = 0.08
GRAVITY = 0.15
MAX_FALL_VELOCITY = 2

CAMERA_FOLLOW_X_OFFSET = {
  right: -20,
  left: -44
}.freeze
CAMERA_FOLLOW_Y_OFFSET = -5

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
  state.rendered_player = {
    animations: load_player_animations,
    sprite: {}.sprite!,
    animation: nil,
    next_animation: nil,
    animation_state: nil
  }
  state.colliders = get_stage_bounds
end

def get_stage_bounds
  [
    { collider: { x: -1000, y: -5, w: 2000, h: 5 } }
  ]
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

  state.rendered_player[:sprite][:x] = state.player[:position][:x] - 8
  state.rendered_player[:sprite][:y] = state.player[:position][:y]
  Camera.apply! camera, state.rendered_player[:sprite]

  state.rendered_player[:next_animation] = :"#{state.player[:state]}_#{state.player[:face_direction]}"
  update_animation(state.rendered_player)

  screen.primitives << state.rendered_player[:sprite]

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

def update(state)
  Player.update!(state.player, state)
  Camera.follow_player! state.camera, state.player
end

$gtk.reset
