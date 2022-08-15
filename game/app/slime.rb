module Slime
  class << self
    def build
      {
        position: { x: 0, y: 0 },
        movement: { x: 0, y: 0 },
        velocity: { x: 0, y: 0 },
        collider_bounds: { x: -5, y: 0, w: 12, h: 8 },
        collider: {},
        state: :move,
        face_direction: :right,
        health: { max: 15, current: 15, ticks_since_hurt: 1000 },
        attack: { preparing_ticks: 0 }
      }
    end

    def update!(slime, state)
      case slime[:state]
      when :move
        wander(slime)
      when :prepare_attack
        slime[:attack][:preparing_ticks] += 1
        fly_towards(slime, state.player) if slime[:attack][:preparing_ticks] >= 90
      when :flying
        slime[:attack][:flying_ticks] += 1
        slime[:state] = :move if slime[:attack][:flying_ticks] >= 120
      end

      handle_movement(slime, state)
      handle_fire(slime, state)
    end

    def update_rendered_state!(slime, rendered_state)
      x_offset = -12
      rendered_state[:sprite].merge! slime[:position]
      rendered_state[:sprite][:x] += x_offset

      rendered_state[:next_animation] = next_animation(slime)
      update_animation rendered_state

      metadata = Animations.current_frame_metadata rendered_state[:animation_state]
      collider_bounds = metadata[:slices][:collider]
      slime[:collider_bounds] = collider_bounds.merge(x: collider_bounds[:x] + x_offset)
    end

    def fly_towards(slime, entity)
      slime[:state] = :flying
      dx = entity[:position][:x] - slime[:position][:x]
      slime[:face_direction] = dx > 0 ? :right : :left
      slime[:velocity][:x] = dx.sign * 1.5
      slime[:attack] = { flying_ticks: 0 }
    end

    private

    def wander(slime)
      slime[:movement][:x] += slime[:face_direction] == :right ? 0.1 : -0.1
    end

    def handle_movement(slime, state)
      movement_result = Movement.apply!(slime, state.colliders)
      if movement_result[:collisions][:left]
        slime[:face_direction] = :right
        slime[:velocity][:x] *= -1
      elsif movement_result[:collisions][:right]
        slime[:face_direction] = :left
        slime[:velocity][:x] *= -1
      end

      if movement_result[:floor_collider]
        slime[:velocity][:y] = 0 if slime[:velocity][:y] < 0
        slime[:movement][:y] = 0 if slime[:movement][:y] < 0
      end
    end

    def handle_fire(slime, state)
      hotmap = state.hotmap
      health = slime[:health]
      touched_fire_particle = Hotmap.first_overlapping_fire_particle(hotmap, slime[:collider])
      if touched_fire_particle && health[:ticks_since_hurt] >= INVINCIBLE_TICKS_AFTER_DAMAGE
        health[:ticks_since_hurt] = 0
        x_sign = touched_fire_particle[:velocity][:x].sign
        slime[:velocity][:x] = x_sign * PLAYER_HURT_SPEED_X
        health[:current] -= 1
        slime[:state] = :prepare_attack
        slime[:attack] = { preparing_ticks: 0 }
      else
        health[:ticks_since_hurt] += 1
      end
    end

    def next_animation(slime)
      case slime[:state]
      when :prepare_attack
        :prepare_attack
      else
        :"#{slime[:state]}_#{slime[:face_direction]}"
      end
    end
  end
end
