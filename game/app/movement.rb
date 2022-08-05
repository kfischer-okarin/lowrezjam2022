module Movement
  class << self
    def apply!(entity)
      apply_gravity(entity)
      move(entity, :x)
      move(entity, :y)
    end

    private

    def apply_gravity(entity)
      entity[:movement][:y] += entity[:y_velocity]
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
  end
end
