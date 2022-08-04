def test_movement(args, assert)
  inputs = args.inputs

  %i[left right].each do |direction|
    inputs.clear
    inputs.keyboard.key_held.send(:"#{direction}=", 1)

    input_actions = InputActions.process_inputs args.inputs

    assert.equal! input_actions, [
      { action: :move, direction: direction }
    ]
  end
end

def test_jump(args, assert)
  args.inputs.keyboard.key_held.space = 1

  input_actions = InputActions.process_inputs args.inputs

  assert.equal! input_actions, [
    { action: :jump }
  ]
end

def test_movement_and_jump(args, assert)
  inputs = args.inputs

  %i[left right].each do |direction|
    inputs.clear
    inputs.keyboard.key_held.send(:"#{direction}=", 1)
    args.inputs.keyboard.key_held.space = 1

    input_actions = InputActions.process_inputs args.inputs

    assert.equal! input_actions.sort_by(&:action), [
      { action: :jump },
      { action: :move, direction: direction }
    ]
  end
end
