module Slime
  class << self
    def build
      {
        position: { x: 0, y: 0 },
        movement: { x: 0, y: 0 },
        y_velocity: 0,
        collider_bounds: { x: -5, y: 0, w: 12, h: 8 },
        collider: {},
        state: :move,
        face_direction: :right
      }
    end

    def update!(slime, state)
      slime[:movement][:x] += slime[:face_direction] == :right ? 0.1 : -0.1
      movement_result = Movement.apply!(slime, state.colliders)
      if movement_result[:collisions][:left]
        slime[:face_direction] = :right
      elsif movement_result[:collisions][:right]
        slime[:face_direction] = :left
      end
    end

    def update_rendered_state!(slime, rendered_state)
      rendered_state[:sprite].merge! slime[:position]
      rendered_state[:sprite][:x] -= 12

      rendered_state[:next_animation] = :"move_#{slime[:face_direction]}"
      update_animation rendered_state
    end
  end
end
