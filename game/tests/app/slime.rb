require 'tests/test_helpers.rb'

def test_slime_should_be_hurt_when_close_to_a_fire_particle(args, assert)
  SlimeTests.test(args) do
    with position: { x: 0, y: 0 }

    fire_particle position: { x: 7, y: 2 }

    update

    assert.equal! slime[:health][:ticks_since_hurt],
                  0,
                  "Expected #{slime_description} to be hurt when close to a fire particle " \
                  "but it wasn't"
  end
end

def test_slime_should_not_be_hurt_right_after_being_hurt(args, assert)
  SlimeTests.test(args) do
    with position: { x: 0, y: 0 }

    fire_particle position: { x: 7, y: 2 }
    update

    update

    assert.true! slime[:health][:ticks_since_hurt] > 0,
                  "Expected #{slime_description} not be hurt twice in a row " \
                  'but it was'
  end
end

def test_slime_should_lose_hp_when_being_hurt(args, assert)
  SlimeTests.test(args) do
    with position: { x: 0, y: 0 }

    fire_particle position: { x: 7, y: 2 }

    hp_before = slime[:health][:current]

    update

    assert.equal! slime[:health][:current],
                  hp_before - 1,
                  "Expected #{slime_description} to have lost hp " \
                  "but it didn't"
  end
end

def test_slime_should_not_be_hurt_when_close_to_a_smoke_particle(args, assert)
  SlimeTests.test(args) do
    with position: { x: 0, y: 0 }

    fire_particle position: { x: 7, y: 2 }, state: :smoke

    update

    assert.true! slime[:health][:ticks_since_hurt] != 0,
                 "Expected #{slime_description} not to be hurt when close to a smoke particle " \
                 'but it was'
  end
end

def test_slime_should_be_hurled_left_sideways_when_hurt_from_the_right(args, assert)
  SlimeTests.test(args) do
    with position: { x: 0, y: 0 }, face_direction: :right

    fire_particle position: { x: 7, y: 2 }, velocity: { x: -1, y: 0 }

    5.times { update }

    assert.true! slime[:position][:x] < 0,
                 "Expected #{slime_description} to be hurled left when hurt from the right " \
                 "but it's position was #{slime[:position]}"
  end
end

def test_slime_should_be_hurled_right_sideways_when_hurt_from_the_left(args, assert)
  SlimeTests.test(args) do
    with position: { x: 0, y: 0 }, face_direction: :left

    fire_particle position: { x: -7, y: 2 }, velocity: { x: 1, y: 0 }

    5.times { update }

    assert.true! slime[:position][:x] > 0,
                 "Expected #{slime_description} to be hurled right when hurt from the left " \
                 "but it's position was #{slime[:position]}"
  end
end

def test_slime_ticks_since_hurt_increase(args, assert)
  SlimeTests.test(args) do
    ticks_since_hurt_before = slime[:health][:ticks_since_hurt]

    update

    assert.equal! slime[:health][:ticks_since_hurt],
                  ticks_since_hurt_before + 1,
                  'Expected slime to increase ticks_since_hurt by 1'
  end
end

module SlimeTests
  class << self
    def test(args, &block)
      TestHelpers::SlimeDSL.new(args).instance_eval(&block)
    end
  end
end
