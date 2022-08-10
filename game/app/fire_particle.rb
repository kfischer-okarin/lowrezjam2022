module FireParticle
  class << self
    def build(x:, y:, direction:)
      {
        position: { x: x, y: y },
        lifetime: 0,
        dead: false,
      }.sprite!(w: 2, h: 2, path: :pixel)
    end

    def update!(particle)
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

      particle[:lifetime] += 1
    end

    private

    WHITE_TICK = 0
    YELLOW_TICK = 5
    BRIGHT_RED_TICK = 13
    RED_TICK = 18
    DARK_BROWN_TICK = 25
    DEATH_TICK = 40
  end
end
