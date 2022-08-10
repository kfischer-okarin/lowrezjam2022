require 'tests/test_helpers.rb'

def test_fire_particle_colors(args, assert)
  FireParticleTests.test(args) do
    colors = []
    repeat_until_death do
      update

      colors << particle.slice(:r, :g, :b)
    end


    assert.equal! colors.uniq, [
      Colors::DawnBringer32::WHITE,
      Colors::DawnBringer32::YELLOW,
      Colors::DawnBringer32::BRIGHT_RED,
      Colors::DawnBringer32::RED,
      Colors::DawnBringer32::DARK_BROWN
    ]
  end
end

module FireParticleTests
  class << self
    def test(args, &block)
      TestHelpers::FireParticleDSL.new(args).instance_eval(&block)
    end
  end
end
