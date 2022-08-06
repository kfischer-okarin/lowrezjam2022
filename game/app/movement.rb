module Movement
  class << self
    def apply!(entity, colliders)
      apply_gravity(entity)
      move(entity, :x, colliders: colliders)
      y_collision = move(entity, :y, colliders: colliders)
      {
        stopped_falling: stop_falling(entity, y_collision)
      }
    end

    private

    def apply_gravity(entity)
      entity[:movement][:y] += entity[:y_velocity]
      entity[:y_velocity] = [entity[:y_velocity] - GRAVITY, -MAX_FALL_VELOCITY].max
    end

    def move(entity, dimension, colliders:)
      abs_movement = entity[:movement][dimension].abs
      sign = entity[:movement][dimension].sign
      entity_at_next_position = {
        position: entity[:position].dup,
        collider_bounds: entity[:collider_bounds],
        collider: entity[:collider].dup
      }
      next_position = entity_at_next_position[:position]
      collided_with = nil

      while abs_movement >= 1
        abs_movement -= 1
        next_position[dimension] += sign
        update_collider entity_at_next_position
        collided_with = check_collision(entity_at_next_position, colliders)
        if collided_with
          next_position[dimension] -= sign
          update_collider entity_at_next_position
          abs_movement = 0
        end
      end

      entity[:position] = next_position
      entity[:collider] = entity_at_next_position[:collider]
      entity[:movement][dimension] = abs_movement * sign
      collided_with
    end

    def update_collider(entity)
      position = entity[:position]
      collider_bounds = entity[:collider_bounds]
      collider = entity[:collider]
      collider[:x] = position[:x] + collider_bounds[:x]
      collider[:y] = position[:y] + collider_bounds[:y]
      collider[:w] = collider_bounds[:w]
      collider[:h] = collider_bounds[:h]
    end

    def check_collision(entity, colliders)
      colliders.find { |collider|
        entity[:collider].intersect_rect? collider[:collider]
      }
    end

    def stop_falling(entity, y_collision)
      return false unless y_collision

      entity[:position][:y] = y_collision[:collider].top
      entity[:y_velocity] = 0
      true
    end
  end
end
