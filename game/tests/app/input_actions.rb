def test_input_actions_movement(args, assert)
  inputs = args.inputs

  %i[left right].each do |direction|
    inputs.clear
    inputs.keyboard.key_held.send(:"#{direction}=", 1)

    input_actions = InputActions.process_inputs args.inputs

    assert.equal! input_actions, { move: direction }
  end
end

def test_input_actions_jump(args, assert)
  args.inputs.keyboard.key_held.space = 1

  input_actions = InputActions.process_inputs args.inputs

  assert.equal! input_actions, { jump: true }
end

def test_input_actions_fire(args, assert)
  args.inputs.keyboard.key_held.x = 1

  input_actions = InputActions.process_inputs args.inputs

  assert.equal! input_actions, { fire: true }
end

def test_input_actions_movement_and_jump(args, assert)
  inputs = args.inputs

  %i[left right].each do |direction|
    inputs.clear
    inputs.keyboard.key_held.send(:"#{direction}=", 1)
    args.inputs.keyboard.key_held.space = 1

    input_actions = InputActions.process_inputs args.inputs

    assert.equal! input_actions, { move: direction, jump: true }
  end
end
