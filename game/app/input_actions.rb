module InputActions
  class << self
    def process_inputs(inputs)
      {}.tap do |actions|
        keyboard = inputs.keyboard

        if inputs.left_right == -1
          actions[:move] = :left
        elsif inputs.left_right == 1
          actions[:move] = :right
        end

        if keyboard.key_held.space
          actions[:jump] = true
        end
      end
    end
  end
end
