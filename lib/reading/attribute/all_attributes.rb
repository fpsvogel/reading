require_relative "attribute"
require_relative "variants_attribute"
require_relative "experiences_attribute"

module Reading
  class Row
    using Util::DeepFetch

    # The simpler attributes are collected below. The more complex attributes
    # are separated into their own files.

    class RatingAttribute < Attribute
      def parse
        return nil unless columns[:rating]

        rating = columns[:rating].strip
        return nil if rating.empty?

        Integer(rating, exception: false) ||
          Float(rating, exception: false)
      end
    end

    class AuthorAttribute < Attribute
      def parse
        item_head
          .remove(/\A#{config.deep_fetch(:csv, :regex, :formats)}/)
          .match(/.+(?=#{config.deep_fetch(:csv, :short_separator)})/)
          &.to_s
          &.strip
      end
    end

    class TitleAttribute < Attribute
      def parse
        item_head
          .remove(/\A#{config.deep_fetch(:csv, :regex, :formats)}/)
          .remove(/.+#{config.deep_fetch(:csv, :short_separator)}/)
          .remove(/#{config.deep_fetch(:csv, :long_separator)}.+\z/)
          .strip
          .presence
      end
    end

    class SeriesAttribute < Attribute
      def parse
        separated = item_head
          .split(config.deep_fetch(:csv, :long_separator))
          .map(&:strip)
          .map(&:presence)
          .compact

        separated.delete_at(0) # everything before the series/extra info

        separated.map { |str|
          volume = str.match(config.deep_fetch(:csv, :regex, :series_volume))
          prefix = "#{config.deep_fetch(:csv, :series_prefix)} "

          if volume || str.start_with?(prefix)
            {
              name: str.delete_suffix(volume.to_s).delete_prefix(prefix) || default[:name],
              volume: volume&.captures&.first&.to_i                      || default[:volume],
            }
          end
        }.compact.presence
      end

      private

      def default
        config.deep_fetch(:item, :template, :series).first
      end
    end

    class GenresAttribute < Attribute
      def parse
        return nil unless columns[:genres]

        columns[:genres]
          .split(config.deep_fetch(:csv, :separator))
          .map(&:strip)
          .map(&:presence)
          .compact.presence
      end
    end

    class NotesAttribute < Attribute
      def parse
        return nil unless columns[:public_notes]

        columns[:public_notes]
          .presence
          &.chomp
          &.remove(/#{config.deep_fetch(:csv, :long_separator).rstrip}\s*\z/)
          &.split(config.deep_fetch(:csv, :long_separator))
          &.map { |string|
            {
              blurb?: !!string.delete!(config.deep_fetch(:csv, :blurb_emoji)),
              private?: !!string.delete!(config.deep_fetch(:csv, :private_emoji)),
              content: string.strip,
            }
          }
      end
    end
  end
end
