module Player
  class << self
    def build
      {
        x: 0, y: 0,
        state: :idle,
        face_direction: :right,
      }
    end

    def update!(player, state)
      case player[:state]
      when :idle
        player[:state] = :run if state.input_actions[:move]
        player[:state] = :jump if state.input_actions[:jump]
      when :run
        player[:state] = :idle unless state.input_actions[:move]
        player[:state] = :jump if state.input_actions[:jump]
      end
    end
  end
end
