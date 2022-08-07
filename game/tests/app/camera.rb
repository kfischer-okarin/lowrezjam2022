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

def test_camera_should_follow_player_when_running_right(args, assert)
  CameraTests.test(args) do
    camera_x_before = camera[:position][:x]

    player_runs :right
    update_camera

    assert.true! camera[:position][:x] > camera_x_before,
                 "Expected camera to follow player right but it didn't"
  end
end

def test_camera_should_follow_player_when_running_left(args, assert)
  CameraTests.test(args) do
    camera_x_before = camera[:position][:x]

    player_runs :left
    update_camera

    assert.true! camera[:position][:x] < camera_x_before,
                 "Expected camera to follow player left but it didn't"
  end
end

def test_camera_should_follow_player_when_jumping_right(args, assert)
  CameraTests.test(args) do
    camera_x_before = camera[:position][:x]

    player_jumps :right
    update_camera

    assert.true! camera[:position][:x] > camera_x_before,
                 "Expected camera to follow player right but it didn't"
  end
end

def test_camera_should_follow_player_when_jumping_left(args, assert)
  CameraTests.test(args) do
    camera_x_before = camera[:position][:x]

    player_jumps :left
    update_camera

    assert.true! camera[:position][:x] < camera_x_before,
                 "Expected camera to follow player left but it didn't"
  end
end

module CameraTests
  class << self
    def test(args, &block)
      TestHelpers::CameraDSL.new(args).instance_eval(&block)
    end
  end
end
