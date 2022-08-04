module InputActions
  class << self
    def process_inputs(inputs)
      [].tap do |actions|
        keyboard = inputs.keyboard

        if inputs.left_right == -1
          actions << { action: :move, direction: :left }
        elsif inputs.left_right == 1
          actions << { action: :move, direction: :right }
        end

        if keyboard.key_held.space
          actions << { action: :jump }
        end
      end
    end
  end
end
