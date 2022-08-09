module Player
  class << self
    def build
      {
        position: { x: 0, y: 0 },
        movement: { x: 0, y: 0 },
        collider_bounds: { x: -4, y: 0, w: 10, h: 23 },
        collider: {},
        y_velocity: 0,
        state: :idle,
        firing: false,
        face_direction: :right,
        can_jump: true
      }
    end

    def update!(player, state)
      input_actions = state.input_actions
      update_state(player, input_actions)
      update_firing(player, input_actions)
      update_face_direction(player, input_actions)
      update_movement(player, input_actions)
      movement_result = Movement.apply!(player, state.colliders)
      land(player, movement_result[:collisions][:down]) if movement_result[:collisions][:down]
      start_falling(player) if movement_result[:position_change][:y].negative?
      stop_vertical_movement(player) if movement_result[:collisions][:up]
    end

    private

    def update_state(player, input_actions)
      case player[:state]
      when :idle
        player[:state] = :run if input_actions[:move]
        start_jump(player) if input_actions[:jump] && player[:can_jump]
        player[:can_jump] = true unless input_actions[:jump]
      when :run
        player[:state] = :idle unless input_actions[:move]
        start_jump(player) if input_actions[:jump] && player[:can_jump]
        player[:can_jump] = true unless input_actions[:jump]
      when :jump
        player[:y_velocity] += PLAYER_JUMP_ACCELERATION if input_actions[:jump] && player[:y_velocity].positive?
      end
    end

    def start_jump(player)
      start_falling(player)
      player[:y_velocity] = PLAYER_JUMP_SPEED
    end

    def start_falling(player)
      player[:state] = :jump
      player[:can_jump] = false
    end

    def update_firing(player, input_actions)
      player[:firing] = !!input_actions[:fire]
    end

    def update_face_direction(player, input_actions)
      if input_actions[:move] && !player[:firing]
        player[:face_direction] = input_actions[:move]
      end
    end

    def update_movement(player, input_actions)
      if input_actions[:move]
        player[:movement][:x] = input_actions[:move] == :right ? PLAYER_RUN_SPEED : -PLAYER_RUN_SPEED
      else
        player[:movement][:x] = 0
      end
    end

    def land(player, collider)
      return unless player[:state] == :jump

      player[:state] = :idle
      player[:position][:y] = collider[:collider].top
      stop_vertical_movement(player)
    end

    def stop_vertical_movement(player)
      player[:y_velocity] = 0
      player[:movement][:y] = 0
    end
  end
end
