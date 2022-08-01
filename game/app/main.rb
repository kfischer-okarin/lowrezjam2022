require 'lib/debug_mode.rb'
require 'lib/extra_keys.rb'
require 'lib/resources.rb'

require 'app/resources.rb'

SCREEN_W = 64
SCREEN_H = 64

def tick(args)
  state = args.state
  render(state, args.outputs)
end

def render(_state, outputs)
  screen = outputs[:screen]
  screen.background_color = [0x18, 0x14, 0x25]
  screen.width = SCREEN_W
  screen.height = SCREEN_H

  outputs.background_color = [0, 0, 0]
  outputs.primitives << { x: 288, y: 8, w: 704, h: 704, path: :screen }.sprite!
end
