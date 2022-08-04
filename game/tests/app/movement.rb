def test_movement(args, assert)
  [
    { movement: { x: 2.5, y: -1.5 }, new_position: { x: 2, y: -1 }, new_movement: { x: 0.5, y: -0.5 } },
    { movement: { x: -1, y: 0 }, new_position: { x: -1, y: 0 }, new_movement: { x: 0, y: 0 } }
  ].each do |test_case|
    player = Player.build
    player[:position] = { x: 0, y: 0 }
    player[:movement] = test_case[:movement]

    Movement.apply!(player)

    assert.equal! player[:position],
                  test_case[:new_position],
                  "Expected #{test_case[:movement]} to change player position to "\
                  "#{test_case[:new_position]} but it was #{player[:position]}"
    assert.equal! player[:movement],
                  test_case[:new_movement],
                  "Expected #{test_case[:movement]} to change player movement to "
                  "#{test_case[:new_movement]} but it was #{player[:movement]}"
  end
end
