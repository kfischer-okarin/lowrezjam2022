module Slime
  class << self
    def build
      {
        position: { x: 0, y: 0 },
        movement: { x: 0, y: 0 },
        velocity: { x: 0, y: 0 },
        collider_bounds: { x: -5, y: 0, w: 12, h: 8 },
        collider: {},
        state: :move,
        face_direction: :right,
        health: { max: 15, current: 15, ticks_since_hurt: 1000 }
      }
    end

    def update!(slime, state)
      handle_basic_movement(slime, state)
      handle_fire(slime, state.hotmap)
    end

    def update_rendered_state!(slime, rendered_state)
      x_offset = -12
      rendered_state[:sprite].merge! slime[:position]
      rendered_state[:sprite][:x] += x_offset

      rendered_state[:next_animation] = :"move_#{slime[:face_direction]}"
      update_animation rendered_state

      metadata = Animations.current_frame_metadata rendered_state[:animation_state]
      collider_bounds = metadata[:slices][:collider]
      slime[:collider_bounds] = collider_bounds.merge(x: collider_bounds[:x] + x_offset)
    end

    private

    def handle_basic_movement(slime, state)
      slime[:movement][:x] += slime[:face_direction] == :right ? 0.1 : -0.1
      movement_result = Movement.apply!(slime, state.colliders)
      if movement_result[:collisions][:left]
        slime[:face_direction] = :right
      elsif movement_result[:collisions][:right]
        slime[:face_direction] = :left
      end
    end

    def handle_fire(slime, hotmap)
      if Hotmap.rect_inside?(hotmap, slime[:collider])
        slime[:health][:ticks_since_hurt] = 0
      end
    end
  end
end
