module Animations
  module AsespriteJson
    class << self
      def read(path)
        sprite_sheet_data = deep_symbolize_keys! $gtk.parse_json_file(path)

        frames = sprite_sheet_data.fetch :frames
        first_frame = frames.first.fetch :frame
        last_slash_index = path.rindex '/'
        base = {
          w: first_frame[:w],
          h: first_frame[:h],
          tile_w: first_frame[:w],
          tile_h: first_frame[:h],
          flip_horizontally: false,
          path: path[0..last_slash_index] + sprite_sheet_data.fetch(:meta).fetch(:image)
        }

        {}.tap { |result|
          slices_data = sprite_sheet_data.fetch(:meta).fetch :slices
          sprite_sheet_data.fetch(:meta).fetch(:frameTags).each do |frame_tag_data|
            tag = frame_tag_data.fetch(:name).to_sym
            frame_range = frame_tag_data.fetch(:from)..frame_tag_data.fetch(:to)
            result[tag.to_sym] = Animations.build(
              frames: frame_range.map { |frame_index|
                frame_data = frames[frame_index]
                frame = frame_data.fetch(:frame)
                {
                  tile_x: frame[:x],
                  tile_y: frame[:y],
                  duration: frame_data.fetch(:duration).idiv(50) * 3, # 50ms = 3 ticks
                  metadata: {
                    slices: {}.tap { |slices|
                      slices_data.each do |slice_data|
                        name = slice_data.fetch(:name).to_sym
                        key_frame = slice_data[:keys].select { |slice_key_data|
                          slice_key_data.fetch(:frame) <= frame_index
                        }.last
                        slices[name] = key_frame.fetch(:bounds)
                      end
                    }
                  }
                }
              },
              **base
            )
          end
        }
      end

      private

      def deep_symbolize_keys!(value)
        case value
        when Hash
          symbolize_keys!(value)
          value.each_value do |hash_value|
            deep_symbolize_keys!(hash_value)
          end
        when Array
          value.each do |array_value|
            deep_symbolize_keys!(array_value)
          end
        end

        value
      end

      def symbolize_keys!(hash)
        hash.each_key do |key|
          next unless key.is_a? String

          hash[key.to_sym] = hash.delete(key)
        end
        hash
      end
    end
  end
end
