module Camera
  class << self
    def build
      {
        position: { x: 0, y: 0 },
        target_position: { x: 0, y: 0 },
        movement: { x: 0, y: 0 }
      }
    end

    def apply!(camera, sprite)
      sprite[:x] -= camera[:position][:x]
      sprite[:y] -= camera[:position][:y]
    end

    def follow_player!(camera, player, immediately: false)
      camera[:target_position] = calc_target_position(player)
      move_to_target_position!(camera, immediately: immediately)
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
      move(camera, :x)
    end

    def smooth_movement_by(offset)
      [
        1 + (offset.abs / 25),
        offset.abs
      ].min * offset.sign
    end

    def move(camera, dimension)
      abs_movement = camera[:movement][dimension].abs
      sign = camera[:movement][dimension].sign
      position = camera[:position]

      while abs_movement >= 1
        abs_movement -= 1
        position[dimension] += sign
      end

      camera[:movement][dimension] = abs_movement * sign
    end
  end
end
