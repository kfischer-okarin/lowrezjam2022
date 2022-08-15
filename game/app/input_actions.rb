module InputActions
  class << self
    def process_inputs(inputs)
      {}.tap do |actions|
        keyboard = inputs.keyboard
        gamepad = inputs.controller_one

        if inputs.left_right == -1
          actions[:move] = :left
        elsif inputs.left_right == 1
          actions[:move] = :right
        end

        actions[:jump] = true if keyboard.up || gamepad.up || gamepad.key_held.a
        actions[:fire] = true if keyboard.key_held.space || gamepad.key_held.x || gamepad.key_held.r2
      end
    end
  end
end
