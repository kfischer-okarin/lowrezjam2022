def test_player_start_running(args, assert)
  player = Player.build
  args.state.input_actions = { move: :right }

  Player.update!(player, args.state)

  assert.equal! player[:state], :run
end

def test_player_stop_running(args, assert)
  player = Player.build
  player[:state] = :run
  args.state.input_actions = {}

  Player.update!(player, args.state)

  assert.equal! player[:state], :idle
end

def test_player_keep_idle(args, assert)
  player = Player.build
  args.state.input_actions = {}

  Player.update!(player, args.state)

  assert.equal! player[:state], :idle
end

def test_player_keep_running(args, assert)
  player = Player.build
  player[:state] = :run
  args.state.input_actions = { move: :right }

  Player.update!(player, args.state)

  assert.equal! player[:state], :run
end

def test_player_start_jumping_when_idle(args, assert)
  [
    { jump: true },
    { move: :right, jump: true },
    { move: :left, jump: true }
  ].each do |input_actions|
    player = Player.build
    args.state.input_actions = input_actions

    Player.update!(player, args.state)

    assert.equal! player[:state], :jump
  end
end

def test_player_start_jumping_when_running(args, assert)
  player = Player.build
  player[:state] = :run
  args.state.input_actions = { jump: true }

  Player.update!(player, args.state)

  assert.equal! player[:state], :jump
end
