module Hotmap
  class << self
    def build
      {}
    end

    def update!(hotmap, particles)
      hotmap.each_value(&:clear)
      particles.each do |particle|
        hotmap_x = to_hotmap_coordinate particle[:position][:x]
        hotmap_y = to_hotmap_coordinate particle[:position][:y]
        hotmap[hotmap_x] ||= {}
        hotmap[hotmap_x][hotmap_y] = true
      end
    end

    def rect_inside?(hotmap, rect)
      hotmap_left = to_hotmap_coordinate rect[:x]
      hotmap_right = to_hotmap_coordinate (rect[:x] + rect[:w])
      hotmap_bottom = to_hotmap_coordinate rect[:y]
      hotmap_top = to_hotmap_coordinate (rect[:y] + rect[:h])
      (hotmap_left..hotmap_right).each do |x|
        (hotmap_bottom..hotmap_top).each do |y|
          return true if (hotmap[x] || {})[y]
        end
      end

      false
    end

    private

    def to_hotmap_coordinate(coordinate)
      (coordinate / HOTMAP_TILE_SIZE).floor
    end
  end
end
