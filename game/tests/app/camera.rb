require 'tests/test_helpers.rb'

def test_camera_apply(args, assert)
  CameraTests.test(args) do
    camera_position x: 10, y: 20
    sprite = { x: 100, y: 100, w: 20, h: 20 }

    Camera.apply! camera, sprite

    assert.equal! sprite, { x: 90, y: 80, w: 20, h: 20 }
  end
end

def test_camera_should_follow_y_position_exactly(args, assert)
  CameraTests.test(args) do
    camera_y_before = camera[:position][:y]

    player[:position][:y] += 10
    update_camera

    assert.equal! camera[:position][:y], camera_y_before + 10
  end
end

module CameraTests
  class << self
    def test(args, &block)
      TestHelpers::CameraDSL.new(args).instance_eval(&block)
    end
  end
end
