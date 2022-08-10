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

def test_fire_particle_go_down_temporarily(args, assert)
  %i[left right].each do |direction|
    FireParticleTests.test(args) do
      particle_direction direction

      results = record_every_tick :position, particle_count: 100

      go_down_ratio = calc_ratio results do |positions|
        first_y = positions.first[:y]
        positions[1..-1].any? { |position| position[:y] < first_y }
      end

      assert.true! go_down_ratio >= 85,
                  "Expected at least 85% of #{particles_description} to go down but it was #{go_down_ratio}%"
    end
  end
end

def test_fire_particle_end_up_higher_than_started(args, assert)
  %i[left right].each do |direction|
    FireParticleTests.test(args) do
      particle_direction direction

      results = record_every_tick :position, particle_count: 100

      end_higher_ratio = calc_ratio results do |positions|
        first_y = positions.first[:y]
        positions.last[:y] > first_y
      end

      assert.true! end_higher_ratio >= 85,
                  "Expected at least 85% of #{particles_description} to end up higher than they started " \
                  "but it was #{end_higher_ratio}%"
    end
  end
end

def test_fire_particle_moving_right(args, assert)
  FireParticleTests.test(args) do
    particle_direction :right

    results = record_every_tick :position, particle_count: 100

    move_right_ratio = calc_ratio results do |positions|
      first_x = positions.first[:x]
      positions[1..-1].any? { |position| position[:x] > first_x }
    end

    assert.true! move_right_ratio >= 99,
                "Expected at least 99% of #{particles_description} to move right " \
                "but it was #{move_right_ratio}%"
  end
end

def test_fire_particle_moving_left(args, assert)
  FireParticleTests.test(args) do
    particle_direction :left

    results = record_every_tick :position, particle_count: 100

    move_left_ratio = calc_ratio results do |positions|
      first_x = positions.first[:x]
      positions[1..-1].any? { |position| position[:x] < first_x }
    end

    assert.true! move_left_ratio >= 99,
                "Expected at least 99% of #{particles_description} to move left " \
                "but it was #{move_left_ratio}%"
  end
end

module FireParticleTests
  class << self
    def test(args, &block)
      TestHelpers::FireParticleDSL.new(args).instance_eval(&block)
    end
  end
end
