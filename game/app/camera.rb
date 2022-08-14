module Camera
  class << self
    def build
      {
        position: { x: 0, y: 0 },
        target_position: { x: 0, y: 0 },
        movement: { x: 0, y: 0 },
        shake: { x: 0, y: 0, trauma: 0 }
      }
    end

    def apply!(camera, sprite)
      sprite[:x] -= camera[:position][:x] + camera[:shake][:x]
      sprite[:y] -= camera[:position][:y] + camera[:shake][:y]
    end

    def follow_player!(camera, player, immediately: false)
      camera[:target_position] = calc_target_position(player)
      move_to_target_position!(camera, immediately: immediately)
    end

    def update_shake!(camera)
      shake = camera[:shake]
      if shake[:trauma].zero?
        shake.merge!(x: 0, y: 0)
        return
      end

      max_shake = shake[:trauma] ** 2 * MAX_SCREEN_SHAKE
      shake[:x] = rand * max_shake * 2 - max_shake
      shake[:y] = rand * max_shake * 2 - max_shake
      shake[:x] = shake[:x].abs.ceil * shake[:x].sign
      shake[:y] = shake[:y].abs.ceil * shake[:y].sign
      shake[:trauma] = [0, shake[:trauma] - SCREEN_SHAKE_DECAY].max
    end

    private

    def calc_target_position(player)
      x_offset = CAMERA_FOLLOW_X_OFFSET[player[:face_direction]]
      {
        x: (player[:position][:x] + x_offset).clamp(CAMERA_MIN_X, CAMERA_MAX_X),
        y: (player[:position][:y] + CAMERA_FOLLOW_Y_OFFSET).clamp(CAMERA_MIN_Y, CAMERA_MAX_Y)
      }
    end

    def move_to_target_position!(camera, immediately:)
      target_position = camera[:target_position]
      if immediately
        camera[:position] = target_position
        return
      end

      dx = target_position[:x] - camera[:position][:x]
      camera[:position][:y] = target_position[:y]
      camera[:movement][:x] += smooth_movement_by dx
      Movement.move(camera, :x)
    end

    def smooth_movement_by(offset)
      [
        1 + (offset.abs / 25),
        offset.abs
      ].min * offset.sign
    end
  end
end
