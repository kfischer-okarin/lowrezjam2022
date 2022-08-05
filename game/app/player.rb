module Player
  class << self
    def build
      {
        position: { x: 0, y: 0 },
        movement: { x: 0, y: 0 },
        y_velocity: 0,
        state: :idle,
        face_direction: :right,
      }
    end

    def update!(player, state)
      input_actions = state.input_actions
      update_state(player, input_actions)
      update_face_direction(player, input_actions)
      update_movement(player, input_actions)
      movement_result = Movement.apply!(player)
      land(player) if movement_result[:stopped_falling]
    end

    private

    def update_state(player, input_actions)
      case player[:state]
      when :idle
        player[:state] = :run if input_actions[:move]
        start_jump(player) if input_actions[:jump]
      when :run
        player[:state] = :idle unless input_actions[:move]
        start_jump(player) if input_actions[:jump]
      end
    end

    def start_jump(player)
      player[:state] = :jump
      player[:y_velocity] = 2
    end

    def update_face_direction(player, input_actions)
      if input_actions[:move]
        player[:face_direction] = input_actions[:move]
      end
    end

    def update_movement(player, input_actions)
      if input_actions[:move]
        player[:movement][:x] = player[:face_direction] == :right ? 1 : -1
      else
        player[:movement][:x] = 0
      end
    end

    def land(player)
      return unless player[:state] == :jump

      player[:state] = :idle
    end
  end
end
