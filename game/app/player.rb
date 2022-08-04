module Player
  class << self
    def build
      {
        position: { x: 0, y: 0 },
        movement: { x: 0, y: 0 },
        state: :idle,
        face_direction: :right,
      }
    end

    def update!(player, state)
      input_actions = state.input_actions
      update_state(player, input_actions)
      update_face_direction(player, input_actions)
      update_movement(player, input_actions)
    end

    private

    def update_state(player, input_actions)
      case player[:state]
      when :idle
        player[:state] = :run if input_actions[:move]
        player[:state] = :jump if input_actions[:jump]
      when :run
        player[:state] = :idle unless input_actions[:move]
        player[:state] = :jump if input_actions[:jump]
      end
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
  end
end
