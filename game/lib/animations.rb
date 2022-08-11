module Animations
  class << self
    def read_asesprite_json(path)
      sprite_sheet_data = deep_symbolize_keys! $gtk.parse_json_file(path)

      frames = sprite_sheet_data.fetch :frames
      first_frame = frames.first.fetch :frame
      last_slash_index = path.rindex '/'
      base = {
        w: first_frame[:w],
        h: first_frame[:h],
        tile_w: first_frame[:w],
        tile_h: first_frame[:h],
        path: path[0..last_slash_index] + sprite_sheet_data.fetch(:meta).fetch(:image)
      }

      {}.tap { |result|
        tags = sprite_sheet_data.fetch(:meta).fetch(:frameTags).map { |frame_tag_data| frame_tag_data.fetch(:name) }
        tags.each do |tag|
          sorted_animation_frames = frames.select { |frame_data|
            frame_data.fetch(:filename).start_with?("#{tag}-----") # avoid frames with same prefix
          }.sort_by(&:filename)

          result[tag.to_sym] = build(
            frames: sorted_animation_frames.map { |frame_data|
              frame = frame_data.fetch(:frame)
              {
                tile_x: frame[:x],
                tile_y: frame[:y],
                ticks: frame_data.fetch(:duration).idiv(50) * 3 # 50ms = 3 ticks
              }
            },
            **base
          )
        end
      }
    end

    def build(frames:, **base)
      {
        base: {
          flip_horizontally: false
        }.merge(base),
        frames: frames
      }
    end

    def flipped_horizontally(animation)
      {
        base: animation[:base].merge(flip_horizontally: true),
        frames: animation[:frames]
      }
    end

    def start!(primitive, animation:, repeat: true)
      {
        animation: animation,
        frame_index: 0,
        ticks: 0,
        repeat: repeat,
        finished: false
      }.tap { |animation_state|
        primitive.merge! animation[:base]
        apply! primitive, animation_state: animation_state
      }
    end

    def apply!(primitive, animation_state:)
      frame = animation_state[:animation][:frames][animation_state[:frame_index]]
      primitive.merge! frame
      primitive.delete :ticks
    end

    def next_tick(animation_state)
      return if finished? animation_state

      frames = animation_state[:animation][:frames]

      animation_state[:ticks] += 1
      if animation_state[:ticks] >= frames[animation_state[:frame_index]][:ticks]
        animation_state[:ticks] = 0

        if animation_state[:frame_index] < frames.length - 1
          animation_state[:frame_index] += 1
          return
        end

        if animation_state[:repeat]
          animation_state[:frame_index] = 0
        else
          animation_state[:finished] = true
        end
      end
    end

    def finished?(animation_state)
      animation_state[:finished]
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
