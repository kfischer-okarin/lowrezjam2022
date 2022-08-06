def test_camera_apply(args, assert)
  camera = Camera.build
  camera[:position] = { x: 10, y: 20 }
  sprite = { x: 100, y: 100, w: 20, h: 20 }

  Camera.apply! camera, sprite

  assert.equal! sprite, { x: 90, y: 80, w: 20, h: 20 }
end

def test_camera_should_follow_y_position_exactly(args, assert)
  camera = Camera.build
  player = Player.build
  player[:position][:y] = 0
  Camera.follow_player! camera, player, immediately: true
  camera_y_before = camera[:position][:y]

  player[:position][:y] = 10
  Camera.follow_player! camera, player

  assert.equal! camera[:position][:y], camera_y_before + 10
end
