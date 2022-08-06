module Movement
  class << self
    def apply!(entity)
      apply_gravity(entity)
      move(entity, :x)
      move(entity, :y)
      {
        stopped_falling: stop_falling(entity)
      }
    end

    private

    def apply_gravity(entity)
      entity[:movement][:y] += entity[:y_velocity]
      entity[:y_velocity] -= GRAVITY
    end

    def move(entity, dimension)
      abs_movement = entity[:movement][dimension].abs
      sign = entity[:movement][dimension].sign
      position = entity[:position]

      while abs_movement >= 1
        position[dimension] += sign
        abs_movement -= 1
        # TODO: collision detection
      end

      entity[:movement][dimension] = abs_movement * sign
    end

    def stop_falling(entity)
      return false unless entity[:position][:y] <= 0 && entity[:y_velocity].negative?

      entity[:position][:y] = 0
      entity[:y_velocity] = 0
      true
    end
  end
end
