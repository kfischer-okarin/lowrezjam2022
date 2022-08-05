def test_player_start_running(args, assert)
  PlayerTests.test(args, assert) do
    input move: :right

    assert.equal! player[:state], :run
  end
end

def test_player_stop_running(args, assert)
  PlayerTests.test(args, assert) do
    with state: :run

    no_input

    assert.equal! player[:state], :idle
  end
end

def test_player_keep_idle(args, assert)
  PlayerTests.test(args, assert) do
    no_input

    assert.equal! player[:state], :idle
  end
end

def test_player_keep_running(args, assert)
  %i[left right].each do |direction|
    PlayerTests.test(args, assert) do
      with state: :run

      input move: direction

      assert.equal! player[:state], :run
    end
  end
end

def test_player_start_jumping_when_idle(args, assert)
  [
    { jump: true },
    { move: :right, jump: true },
    { move: :left, jump: true }
  ].each do |input_actions|
    PlayerTests.test(args, assert) do
      input input_actions

      assert.equal! player[:state], :jump
    end
  end
end

def test_player_start_jumping_when_running(args, assert)
  PlayerTests.test(args, assert) do
    with state: :run

    input jump: true

    assert.equal! player[:state], :jump
  end
end

def test_player_face_direction(args, assert)
  %i[left right].each do |initial_face_direction|
    %i[left right].each do |move_direction|
      %i[idle run jump].each do |state|
        PlayerTests.test(args, assert) do
          with state: state, face_direction: initial_face_direction

          input move: move_direction

          assert.equal! player[:face_direction],
                        move_direction,
                        "Expected #{last_input_actions} to change #{player_description} " \
                        "to have face_direction #{move_direction} but it was #{player[:face_direction]}"
        end
      end
    end
  end
end

def test_player_movement(args, assert)
  [
    { direction: :right, movement: { x: 1, y: 0 } },
    { direction: :left, movement: { x: -1, y: 0 } },
  ].each do |test_case|
    %i[idle run jump].each do |state|
      PlayerTests.test(args, assert) do
        with state: state

        input move: test_case[:direction]

        assert.equal! player[:movement],
                      test_case[:movement],
                      "Expected #{last_input_actions} to change #{player_description} " \
                      "to have movement #{test_case[:movement]} but it was #{player[:movement]}"
      end
    end
  end
end

def test_player_movement_stop_moving(args, assert)
  %i[run jump].each do |state|
    PlayerTests.test(args, assert) do
      with state: state, movement: { x: 1, y: 0 }

      no_input

      assert.equal! player[:movement],
                    { x: 0, y: 0 },
                    "Expected #{last_input_actions} to make #{player_description} " \
                    'stop moving'
    end
  end
end

def test_player_should_have_vertical_movement_after_jumping(args, assert)
  %i[idle run].each do |state|
    PlayerTests.test(args, assert) do
      with state: state

      input jump: true

      assert.true! player[:movement][:y] > 0,
                   "Expected #{last_input_actions} to give #{player_description} " \
                   "vertical movement but it was #{player[:movement]}"
    end
  end
end

module PlayerTests
  class << self
    def test(args, assert, &block)
      PlayerTestDSL.new(args, assert).instance_eval(&block)
    end
  end

  class PlayerTestDSL
    attr_reader :player, :last_input_actions

    def initialize(args, assert)
      @args = args
      @assert = assert
      @player = Player.build
      @initial_attributes = nil
    end

    def with(initial_attributes)
      @initial_attributes = initial_attributes
      @initial_attributes.each do |attribute, value|
        player[attribute] = value.dup
      end
    end

    def input(actions)
      @last_input_actions = actions
      @args.state.input_actions = actions

      Player.update!(@player, @args.state)
    end

    def no_input
      input({})
    end

    def player_description
      "player with #{@initial_attributes}"
    end
  end
end
