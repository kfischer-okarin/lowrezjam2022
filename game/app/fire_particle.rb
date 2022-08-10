module FireParticle
  class << self
    def build(x:, y:, direction:)
      {
        position: { x: x, y: y },
        movement: { x: 0, y: 0 },
        velocity: {
          x: direction == :left ? -FIRE_PARTICLE_INITIAL_SPEED : FIRE_PARTICLE_INITIAL_SPEED,
          y: 0
        },
        rotation_sign: direction == :left ? -1 : 1,
        lifetime: 0,
        dead: false
      }.sprite!(w: 2, h: 2, path: :pixel).tap { |particle|
        rotate_particle_velocity_by particle, -0.4
      }
    end

    def update!(particle)
      update_position particle
      update_state particle
      update_direction particle
      particle[:lifetime] += 1
    end

    private

    def update_position(particle)
      particle[:movement][:x] += particle[:velocity][:x]
      particle[:movement][:y] += particle[:velocity][:y]
      Movement.move particle, :x
      Movement.move particle, :y
    end

    def update_state(particle)
      case particle[:lifetime]
      when WHITE_TICK
        particle.merge! Colors::DawnBringer32::WHITE
      when YELLOW_TICK
        particle.merge! Colors::DawnBringer32::YELLOW
      when BRIGHT_RED_TICK
        particle.merge! Colors::DawnBringer32::BRIGHT_RED
      when RED_TICK
        particle.merge! Colors::DawnBringer32::RED
      when DARK_BROWN_TICK
        particle.merge! Colors::DawnBringer32::DARK_BROWN
      when DEATH_TICK
        particle[:dead] = true
      end
    end

    def update_direction(particle)
      case particle[:lifetime]
      when WHITE_TICK
        rotate_particle_velocity_by particle, (rand * 0.6 - 0.2)
      when YELLOW_TICK..RED_TICK
        rotate_particle_velocity_by particle, (rand * 0.4 - 0.1)
      end
    end

    WHITE_TICK = 0
    YELLOW_TICK = 5
    BRIGHT_RED_TICK = 13
    RED_TICK = 18
    DARK_BROWN_TICK = 25
    DEATH_TICK = 40

    def rotate_particle_velocity_by(particle, angle)
      rotate_by particle[:velocity], particle[:rotation_sign] * angle
    end

    def rotate_by(vector, angle)
      length = Math.sqrt(vector[:x] ** 2 + vector[:y] ** 2)
      new_angle = vector_angle(vector) + angle
      vector[:x] = length * Math.cos(new_angle)
      vector[:y] = length * Math.sin(new_angle)
    end

    def vector_angle(vector)
      Math.atan2 vector[:y], vector[:x]
    end
  end
end
