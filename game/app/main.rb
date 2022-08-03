require 'lib/animations.rb'
require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'

require 'app/resources.rb'

SCREEN_W = 64
SCREEN_H = 64

def tick(args)
  state = args.state
  setup(state) if args.tick_count.zero?
  render(state, args.outputs)
end

def setup(state)
  state.player = {
    x: 0, y: 0,
    state: :run,
    face_direction: :right,
  }
  state.rendered_player = {
    entity: state.player,
    animations: load_player_animations,
    sprite: {}.sprite!,
    animation_type: nil,
    animation_state: nil
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

  update_animation(state.rendered_player)
  screen.primitives << state.rendered_player[:sprite]

  outputs.background_color = [0, 0, 0]
  outputs.primitives << { x: 288, y: 8, w: 704, h: 704, path: :screen }.sprite!
end

def update_animation(render_state)
  entity = render_state[:entity]
  animation_type = :"#{entity.state}_#{entity.face_direction}"
  if render_state[:animation_type] == animation_type
    Animations.next_tick render_state[:animation_state]
    Animations.apply! render_state[:sprite], animation_state: render_state[:animation_state]
  else
    render_state[:animation_type] = animation_type
    render_state[:animation_state] = Animations.start!(
      render_state[:sprite],
      animation: render_state[:animations][animation_type]
    )
  end
end

$gtk.reset
