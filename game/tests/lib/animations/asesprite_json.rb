def test_animations_asesprite_json_read(_args, assert)
  animations = Animations::AsespriteJson.read 'tests/resources/character.json'
  expected_animations = {
    idle_right: Animations.build(
      w: 48, h: 48, tile_w: 48, tile_h: 48, path: 'tests/resources/character.png',
      flip_horizontally: false,
      frames: [
        {
          tile_x: 0, tile_y: 0,
          duration: 6,
          metadata: {
            slices: {
              collider: { x: 5, y: 0, w: 20, h: 20 }
            }
          }
        }
      ]
    ),
    walk_right: Animations.build(
      w: 48, h: 48, tile_w: 48, tile_h: 48, path: 'tests/resources/character.png',
      flip_horizontally: false,
      frames: [
        {
          tile_x: 48, tile_y: 0,
          duration: 3,
          metadata: {
            slices: {
              collider: { x: 6, y: 0, w: 22, h: 20 }
            }
          }
        },
        {
          tile_x: 96, tile_y: 0,
          duration: 9,
          metadata: {
            slices: {
              collider: { x: 6, y: 0, w: 22, h: 20 }
            }
          }
        }
      ]
    )
  }

  assert.equal! animations, expected_animations
end
