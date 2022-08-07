module Camera
  class << self
    def build
      {
        position: { x: 0, y: 0 }
      }
    end

    def apply!(camera, sprite)
      sprite[:x] -= camera[:position][:x]
      sprite[:y] -= camera[:position][:y]
    end

    def follow_player!(camera, player, immediately: false)
      x_offset = CAMERA_FOLLOW_X_OFFSET[player[:face_direction]]
      camera[:position][:x] = player[:position][:x] + x_offset
      camera[:position][:y] = player[:position][:y] + CAMERA_FOLLOW_Y_OFFSET
    end
  end
end
