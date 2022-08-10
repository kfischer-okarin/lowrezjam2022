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

    safe_loop "Expected camera to move but it didn't" do
      update_camera

      break if camera[:position][:x] != camera_x_before
    end

    assert.true! camera[:position][:x] > camera_x_before,
                 "Expected camera to follow player right but it didn't"
  end
end

def test_camera_should_follow_player_when_running_left(args, assert)
  CameraTests.test(args) do
    camera_x_before = camera[:position][:x]
    player_runs :left

    safe_loop "Expected camera to move but it didn't" do
      update_camera

      break if camera[:position][:x] != camera_x_before
    end

    assert.true! camera[:position][:x] < camera_x_before,
                 "Expected camera to follow player left but it didn't"
  end
end

def test_camera_should_follow_player_when_jumping_right(args, assert)
  CameraTests.test(args) do
    camera_x_before = camera[:position][:x]
    player_jumps :right

    safe_loop "Expected camera to move but it didn't" do
      update_camera

      break if camera[:position][:x] != camera_x_before
    end

    assert.true! camera[:position][:x] > camera_x_before,
                 "Expected camera to follow player right but it didn't"
  end
end

def test_camera_should_follow_player_when_jumping_left(args, assert)
  CameraTests.test(args) do
    camera_x_before = camera[:position][:x]
    player_jumps :left

    safe_loop "Expected camera to move but it didn't" do
      update_camera

      break if camera[:position][:x] != camera_x_before
    end

    assert.true! camera[:position][:x] < camera_x_before,
                 "Expected camera to follow player left but it didn't"
  end
end

def test_camera_should_look_right_when_player_faces_right(args, assert)
  CameraTests.test(args) do
    player_runs :right

    safe_loop "Expected camera to stop moving but it didn't" do
      x_position_before = camera[:position][:x]

      update_camera

      break if x_position_before == camera[:position][:x]
    end

    assert.true! camera[:position][:x] + 32 > player[:position][:x],
                 "Expected camera to focus right of the player but it didn't"
  end
end

def test_camera_should_look_left_when_player_faces_left(args, assert)
  CameraTests.test(args) do
    player_runs :left

    safe_loop "Expected camera to stop moving but it didn't" do
      x_position_before = camera[:position][:x]

      update_camera

      break if x_position_before == camera[:position][:x]
    end

    assert.true! camera[:position][:x] + 32 < player[:position][:x],
                 "Expected camera to focus left of the player but it didn't"
  end
end

def test_camera_should_not_move_too_suddenly(args, assert)
  CameraTests.test(args) do
    camera_x_before = camera[:position][:x]

    player_runs :right
    update_camera

    assert.true! (camera[:position][:x] - camera_x_before).abs < 10,
                 "Expected camera to move slowly but it didn't"

    camera_x_before = camera[:position][:x]

    player_runs :left
    update_camera

    assert.true! (camera[:position][:x] - camera_x_before).abs < 10,
                 "Expected camera to move slowly but it didn't"
  end
end

def test_camera_should_clamp(args, assert)
  [
    {
      player_position: { x: CAMERA_MIN_X - 100, y: CAMERA_MIN_Y - 100 },
      final_camera_position: { x: CAMERA_MIN_X, y: CAMERA_MIN_Y }
    },
    {
      player_position: { x: CAMERA_MAX_X + 100, y: CAMERA_MAX_Y + 100 },
      final_camera_position: { x: CAMERA_MAX_X, y: CAMERA_MAX_Y }
    }
  ].each do |test_case|
    CameraTests.test(args) do
      player[:position] = test_case[:player_position]

      safe_loop "Expected camera to stop but it didn't" do
        position_before = camera[:position].dup

        update_camera

        break if position_before == camera[:position]
      end

      assert.equal! camera[:position],
                    test_case[:final_camera_position],
                    "Expected camera to end at position #{test_case[:final_camera_position]} " \
                    "but it ended at #{camera[:position]}"
    end
  end
end

module CameraTests
  class << self
    def test(args, &block)
      TestHelpers::CameraDSL.new(args).instance_eval(&block)
    end
  end
end
