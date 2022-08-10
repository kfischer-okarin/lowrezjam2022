require 'tests/test_helpers.rb'

def test_fire_particle_colors(args, assert)
  FireParticleTests.test(args) do
    results = record_every_tick %i[r g b], particle_count: 100

    expected_colors =[
      Colors::DawnBringer32::WHITE,
      Colors::DawnBringer32::YELLOW,
      Colors::DawnBringer32::BRIGHT_RED,
      Colors::DawnBringer32::RED,
      Colors::DawnBringer32::DARK_BROWN
    ]
    right_color_ratio = calc_ratio results do |colors|
      colors.uniq == expected_colors
    end

    assert.equal! right_color_ratio,
                  100,
                  "Expected 100% of particles to be colored #{expected_colors} but got #{right_color_ratio}%"
  end
end

module FireParticleTests
  class << self
    def test(args, &block)
      TestHelpers::FireParticleDSL.new(args).instance_eval(&block)
    end
  end
end
