def test_animations_asesprite_json_read(_args, assert)
  animations = Animations::AsespriteJson.read 'tests/resources/character.json'
  expected_animations = {
    idle_right: Animations.build(
      w: 48, h: 48, tile_w: 48, tile_h: 48, path: 'tests/resources/character.png',
      frames: [
        { tile_x: 0, tile_y: 0, duration: 6 }
      ]
    ),
    walk_right: Animations.build(
      w: 48, h: 48, tile_w: 48, tile_h: 48, path: 'tests/resources/character.png',
      frames: [
        { tile_x: 48, tile_y: 0, duration: 3 },
        { tile_x: 96, tile_y: 0, duration: 9 }
      ]
    )
  }

  assert.equal! animations, expected_animations
end
