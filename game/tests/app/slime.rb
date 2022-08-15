require 'tests/test_helpers.rb'

def test_slime_should_be_hurt_when_close_to_a_fire_particle(args, assert)
  SlimeTests.test(args) do
    with position: { x: 0, y: 0 }

    fire_particle at: { x: 7, y: 2 }

    update

    assert.equal! slime[:health][:ticks_since_hurt],
                  0,
                  "Expected #{slime_description} to be hurt when close to a fire particle " \
                  "but it wasn't"
  end
end

def test_slime_should_not_be_hurt_when_close_to_a_smoke_particle(args, assert)
  SlimeTests.test(args) do
    with position: { x: 0, y: 0 }

    fire_particle at: { x: 7, y: 2 }, state: :smoke

    update

    assert.true! slime[:health][:ticks_since_hurt] != 0,
                 "Expected #{slime_description} not to be hurt when close to a smoke particle " \
                 'but it was'
  end
end

module SlimeTests
  class << self
    def test(args, &block)
      TestHelpers::SlimeDSL.new(args).instance_eval(&block)
    end
  end
end
