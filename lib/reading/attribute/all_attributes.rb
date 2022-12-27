require_relative "attribute"
require_relative "variants/variants_attribute"
require_relative "experiences/experiences_attribute"

module Reading
  class Row
    using Util::StringRemove
    using Util::HashArrayDeepFetch

    # The simpler attributes are collected below. The more complex attributes
    # are separated into their own files.

    class RatingAttribute < Attribute
      def parse
        return nil unless columns[:rating]

        rating = columns[:rating].strip
        return nil if rating.empty?

        Integer(rating, exception: false) ||
          Float(rating, exception: false) ||
          (raise InvalidRatingError, "Invalid rating")
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
        if item_head.end_with?(config.deep_fetch(:csv, :short_separator).rstrip)
          raise InvalidHeadError, "Missing title? Head column ends in a separator"
        end

        item_head
          .remove(/\A#{config.deep_fetch(:csv, :regex, :formats)}/)
          .remove(/.+#{config.deep_fetch(:csv, :short_separator)}/)
          .remove(/#{config.deep_fetch(:csv, :long_separator)}.+\z/)
          .strip
          .presence || (raise InvalidHeadError, "Missing title")
      end
    end

    class GenresAttribute < Attribute
      def parse
        return nil unless columns[:genres]

        columns[:genres]
          .split(config.deep_fetch(:csv, :separator))
          .map(&:strip)
          .map(&:downcase)
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
