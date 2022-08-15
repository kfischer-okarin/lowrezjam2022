module TestHelpers
  module DSL
    class Base
      def initialize(args)
        @args = args
        @args.tick_count = 0
      end

      def tick_count
        @args.tick_count
      end

      def safe_loop(fail_message, &block)
        start_tick = tick_count
        loop do
          instance_eval(&block)

          next unless tick_count > start_tick + 1000
          raise fail_message
        end
      end

      def next_tick
        @args.tick_count += 1
      end

      def assign_attributes(entity, attributes)
        attributes.each do |attribute, value|
          entity[attribute] = value.dup
        end
      end
    end

    module Colliders
      def initialize(args)
        super

        @args.state.colliders = [
          { collider: { x: -1000, y: -5, w: 2000, h: 5 } }
        ]
      end

      def collider_at(x:, y:, w:, h:)
        @args.state.colliders << { collider: { x: x, y: y, w: w, h: h } }
      end
    end
  end

  class PlayerDSL < DSL::Base
    include DSL::Colliders

    attr_reader :player, :last_input_actions

    def initialize(args)
      super

      @player = Player.build
      @initial_attributes = nil
      @args.state.dangers = []
    end

    def with(initial_attributes)
      @initial_attributes = initial_attributes
      assign_attributes @player, initial_attributes
    end

    def input(actions)
      @last_input_actions = actions
      @args.state.input_actions = actions

      Player.update!(@player, @args.state)

      next_tick
    end

    def no_input
      input({})
    end

    def slime_is(at:)
      slime = Slime.build
      slime[:position] = at
      Movement.update_collider slime
      @args.state.slime = slime
      @args.state.dangers << slime
    end

    def player_description
      "player with #{@initial_attributes}"
    end
  end

  class CameraDSL < DSL::Base
    attr_reader :player, :camera

    def initialize(args)
      super

      @player = Player.build
      @player[:position][:x] = 100
      @camera = Camera.build
      Camera.follow_player! @camera, @player, immediately: true
    end

    def camera_position(x:, y:)
      @camera[:position] = { x: x, y: y }
    end

    def player_runs(direction)
      @player[:state] = :run
      move_player(direction)
    end

    def player_jumps(direction)
      @player[:state] = :jump
      move_player(direction)
    end

    def update_camera
      Camera.follow_player! @camera, @player
    end

    private

    def move_player(direction)
      @player[:face_direction] = direction
      @player[:position][:x] += direction == :right ? PLAYER_RUN_SPEED : -PLAYER_RUN_SPEED
    end
  end

  class FireParticleDSL < DSL::Base
    attr_reader :particle

    def initialize(args)
      super

      @particle = FireParticle.build x: 0, y: 0, direction: :right
      @particle_direction = :right
    end

    def particle_direction(direction)
      @particle_direction = direction
    end

    def record_every_tick(recorded_attributes, particle_count:)
      record_value = case recorded_attributes
                     when Array
                       ->(particle) { particle.slice(*recorded_attributes).transform_values(&:dup) }
                     when Symbol
                        ->(particle) { particle[recorded_attributes].dup }
                     end
      [].tap { |results|
        attributes = { x: 0, y: 0, direction: @particle_direction }
        particle_count.times do
          @particle = FireParticle.build attributes
          result = []
          repeat_until_gone do
            update
            result << record_value.call(@particle)
          end
          results << result
        end
      }
    end

    def calc_ratio(results, &condition)
      true_count = 0
      results.each do |result|
        true_count += 1 if condition.call result
      end
      true_count.to_f * 100 / results.size
    end

    def update
      FireParticle.update! @particle
      next_tick
    end

    def repeat_until_gone(&block)
      safe_loop "Expected particle to die but it didn't" do
        block.call
        break if particle[:state] == :gone
      end
    end

    def particles_description
      "particles going #{@particle_direction}"
    end
  end

  class SlimeDSL < DSL::Base
    include DSL::Colliders

    attr_reader :slime

    def initialize(args)
      super

      @slime = Slime.build
      Movement.update_collider @slime
      @initial_attributes = nil
      @args.state.hotmap = Hotmap.build
      @args.state.fire_particles = []
    end

    def with(initial_attributes)
      @initial_attributes = initial_attributes
      assign_attributes @slime, initial_attributes
      Movement.update_collider @slime
    end

    def player_with(attributes)
      player = Player.build
      assign_attributes player, attributes
      @args.state.player = player
    end

    def update
      Slime.update! @slime, @args.state
      next_tick
    end

    def fire_particle(position:, direction: :right, **attributes)
      particle = FireParticle.build(x: position[:x], y: position[:y], direction: direction)
      particle.merge! attributes
      @args.state.fire_particles << particle

      Hotmap.update! @args.state.hotmap, @args.state.fire_particles
    end

    def slime_description
      "slime with #{@initial_attributes}"
    end
  end
end
