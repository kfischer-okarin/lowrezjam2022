module Hotmap
  class << self
    def build
      {}
    end

    def update!(hotmap, particles)
      hotmap.each_value(&:clear)
      particles.each do |particle|
        next unless particle[:state] == :fire

        hotmap_x = to_hotmap_coordinate particle[:position][:x]
        hotmap_y = to_hotmap_coordinate particle[:position][:y]
        hotmap[hotmap_x] ||= {}
        hotmap[hotmap_x][hotmap_y] ||= []
        hotmap[hotmap_x][hotmap_y] << particle
      end
    end

    def first_overlapping_fire_particle(hotmap, rect)
      hotmap_left = to_hotmap_coordinate rect[:x]
      hotmap_right = to_hotmap_coordinate (rect[:x] + rect[:w])
      hotmap_bottom = to_hotmap_coordinate rect[:y]
      hotmap_top = to_hotmap_coordinate (rect[:y] + rect[:h])

      (hotmap_left..hotmap_right).each do |x|
        (hotmap_bottom..hotmap_top).each do |y|
          particles = (hotmap[x] || {})[y]
          next unless particles
          return particles.first
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
