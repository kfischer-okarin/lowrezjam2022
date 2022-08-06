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

def test_player_stop_jumping(args, assert)
  PlayerTests.test(args, assert) do
    with state: :jump, position: { x: 0, y: 5 }

    safe_loop "Expected #{player_description} to become idle, but he didn't" do
      no_input

      break if player[:state] != :jump
    end

    assert.ok!
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

def test_player_move_right(args, assert)
  %i[idle run jump].each do |state|
    PlayerTests.test(args, assert) do
      with state: state, position: { x: 0, y: 0 }

      input move: :right

      assert.true! player[:position][:x] > 0,
                   "Expected #{last_input_actions} to change #{player_description} " \
                   "to have a x position > 0 but it was #{player[:position]}"
    end
  end
end

def test_player_move_left(args, assert)
  %i[idle run jump].each do |state|
    PlayerTests.test(args, assert) do
      with state: state, position: { x: 0, y: 0 }

      input move: :left

      assert.true! player[:position][:x] < 0,
                   "Expected #{last_input_actions} to change #{player_description} " \
                   "to have a x position < 0 but it was #{player[:position]}"
    end
  end
end

def test_player_movement_stop_moving(args, assert)
  %i[run jump].each do |state|
    PlayerTests.test(args, assert) do
      with state: state
      input move: :right
      x_before_stopping = player[:position][:x]

      no_input

      assert.equal! player[:position][:x],
                    x_before_stopping,
                    "Expected #{last_input_actions} to make #{player_description} " \
                    "stop moving x position changed from #{x_before_stopping} to #{player[:position][:x]}"
    end
  end
end

def test_player_should_move_up_after_jumping(args, assert)
  %i[idle run].each do |state|
    PlayerTests.test(args, assert) do
      with state: state, position: { x: 0, y: 0 }

      input jump: true

      assert.true! player[:position][:y] > 0,
                   "Expected #{last_input_actions} to move #{player_description} " \
                   "upwards movement but it was #{player[:position]}"
    end
  end
end

def test_player_should_move_up_several_ticks_after_jumping(args, assert)
  %i[idle run].each do |state|
    PlayerTests.test(args, assert) do
      with state: state
      input jump: true

      2.times do
        y_before_tick = player[:position][:y]

        no_input

        assert.true! player[:position][:y] > y_before_tick,
                     "Expected #{last_input_actions} to move #{player_description} " \
                     "upwards for more than #{tick_count} ticks " \
                     "but y position change was: #{player[:position][:y] - y_before_tick}"
      end
    end
  end
end

def test_player_should_eventually_move_down_after_jumping(args, assert)
  %i[idle run].each do |state|
    PlayerTests.test(args, assert) do
      with state: state
      input jump: true

      safe_loop "Expected #{player_description} to eventually fall down after jumping, but he didn't" do
        y_before_tick = player[:position][:y]

        no_input

        break if player[:position][:y] < y_before_tick
      end
    end
  end

  assert.ok!
end

def test_player_should_only_fall_until_the_floor(args, assert)
  %i[idle run].each do |state|
    PlayerTests.test(args, assert) do
      with state: state
      input jump: true

      safe_loop "Expected #{player_description} to reach the ground, but he didn't" do
        y_before_tick = player[:position][:y]

        no_input

        break if player[:position][:y].zero? && y_before_tick == player[:position][:y]

        next unless player[:position][:y] < 0

        raise "Expected #{player_description} to reach the ground, but he fell through"
      end
    end
  end

  assert.ok!
end

def test_player_should_not_be_able_to_jump_again_without_releasing_the_jump_button(args, assert)
  %i[idle run].each do |state|
    PlayerTests.test(args, assert) do
      with state: state
      input jump: true
      no_input # Releasing jump button mid-air doesn't count as releasing

      safe_loop "Expected #{player_description} to land, but he didn't" do
        input jump: true

        break if player[:state] == :idle
      end

      input jump: true

      assert.equal! player[:state],
                    :idle,
                    'Expected player not to be able to jump again ' \
                    'without releasing the jump button but he could'

      no_input
      input jump: true

      assert.equal! player[:state],
                    :jump,
                    'Expected player to be able to jump again ' \
                    "after releasing the jump button but he couldn't"
    end
  end

  assert.ok!
end

def test_player_should_jump_higher_when_holding_the_jump_button(args, assert)
  %i[idle run].each do |state|
    max_height_without_holding_the_button = 0
    max_height_with_holding_the_button = 0

    PlayerTests.test(args, assert) do
      with state: state
      input jump: true

      safe_loop "Expected #{player_description} to reach the ground, but he didn't" do
        max_height_without_holding_the_button = [max_height_without_holding_the_button, player[:position][:y]].max

        no_input

        break if player[:state] == :idle
      end
    end

    PlayerTests.test(args, assert) do
      with state: state
      input jump: true

      safe_loop "Expected #{player_description} to reach the ground, but he didn't" do
        max_height_with_holding_the_button = [max_height_with_holding_the_button, player[:position][:y]].max

        input jump: true

        break if player[:state] == :idle
      end
    end

    assert.true! max_height_with_holding_the_button > max_height_without_holding_the_button,
                 'Expected player to jump higher when holding the jump button, ' \
                 "but with holding (y position: #{max_height_with_holding_the_button}) " \
                 "was not higher than without holding (y position: #{max_height_without_holding_the_button})"
  end
end

def test_player_should_not_fall_slower_when_holding_the_jump_button(args, assert)
  %i[idle run].each do |state|
    y_after_holding_button_when_falling = 0
    y_after_just_falling = 0

    PlayerTests.test(args, assert) do
      with state: state
      input jump: true

      safe_loop "Expected #{player_description} to start falling, but he didn't" do
        y_before_tick = player[:position][:y]

        input jump: true

        break if player[:position][:y] < y_before_tick
      end

      10.times { input jump: true }

      y_after_holding_button_when_falling = player[:position][:y]
    end

    PlayerTests.test(args, assert) do
      with state: state
      input jump: true

      safe_loop "Expected #{player_description} to start falling, but he didn't" do
        y_before_tick = player[:position][:y]

        input jump: true

        break if player[:position][:y] < y_before_tick
      end

      10.times { no_input }

      y_after_just_falling = player[:position][:y]
    end

    assert.equal! y_after_holding_button_when_falling, y_after_just_falling,
                 "Expected player to not fall slower when holding the jump button, " \
                 "but with holding (y position: #{y_after_holding_button_when_falling}) " \
                 "was higher than without holding (y position: #{y_after_just_falling})"
  end
end

def test_player_should_have_maximum_falling_speed(args, assert)
  PlayerTests.test(args, assert) do
    with state: :jump, position: { x: 0, y: 50 }
    last_y_velocity = player[:y_velocity]

    safe_loop "Expected #{player_description} to reach maximum speed, but he didn't" do
      no_input

      y_velocity = player[:y_velocity]

      break if y_velocity == last_y_velocity

      raise 'Player reached floor before reaching maximum speed' if player[:state] == :idle

      last_y_velocity = y_velocity
    end

    assert.ok!
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
      @args.tick_count = 0
      @args.state.colliders = get_stage_bounds
      @assert = assert
      @player = Player.build
      @initial_attributes = nil
    end

    def tick_count
      @args.tick_count
    end

    def with(initial_attributes)
      @initial_attributes = initial_attributes
      @initial_attributes.each do |attribute, value|
        player[attribute] = value.dup
      end
    end

    def safe_loop(fail_message, &block)
      start_tick = tick_count
      loop do
        instance_eval(&block)

        next unless tick_count > start_tick + 1000
        raise fail_message
      end
    end

    def input(actions)
      @last_input_actions = actions
      @args.state.input_actions = actions

      Player.update!(@player, @args.state)

      @args.tick_count += 1
    end

    def no_input
      input({})
    end

    def player_description
      "player with #{@initial_attributes}"
    end
  end
end
