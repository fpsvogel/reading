require_relative "../errors"
require_relative "../util/blank"
require_relative "../util/deep_fetch"
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
          .sub(/\A#{@config.deep_fetch(:csv, :regex, :formats)}/, "")
          .match(/.+(?=#{@config.deep_fetch(:csv, :short_separator)})/)
          &.to_s
          &.strip
      end
    end

    class TitleAttribute < Attribute
      def parse
        item_head
          .sub(/\A#{@config.deep_fetch(:csv, :regex, :formats)}/, "")
          .sub(/.+#{@config.deep_fetch(:csv, :short_separator)}/, "")
          .sub(/#{@config.deep_fetch(:csv, :long_separator)}.+\z/, "")
          .strip
          .presence
      end
    end

    class SeriesAttribute < Attribute
      def parse
        separated = item_head
          .split(@config.deep_fetch(:csv, :long_separator))
          .map(&:strip)
          .map(&:presence)
          .compact

        separated.delete_at(0) # everything before the series/extra info

        separated.map { |str|
          volume = str.match(@config.deep_fetch(:csv, :regex, :series_volume))
          prefix = "#{@config.deep_fetch(:csv, :series_prefix)} "

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
        @config.deep_fetch(:item, :template, :series).first
      end
    end

    # Not an item attribute; only shares common behavior across the below
    # attribute parsers.
    class FromGenreColumnAttributeBase < Attribute
      def all_genres(columns)
        columns[:genres]
          .split(@config.deep_fetch(:csv, :separator))
          .map(&:strip)
          .map(&:presence)
          .compact.presence
      end
    end

    class VisibilityAttribute < FromGenreColumnAttributeBase
      VISIBILITY_STRINGS =
        {
          0 => ["private", "for me", "to me", "for-me", "to-me"],
          1 => ["for starred friends", "to starred friends",
                "for-starred-friends", "to-starred-friends",
                "for starred", "to starred", "for-starred", "to-starred"],
          2 => ["for friends", "to friends", "for-friends", "to-friends"],
        }

      def parse
        return nil unless columns[:genres]

        visibility = @config.deep_fetch(:item, :template, :visibility)

        all_genres(columns).each do |entry|
          if specified_visibility = visibility_string_to_number(entry)
            visibility = specified_visibility
            break
          end
        end

        visibility
      end

      private

      def visibility_string_to_number(entry)
        VISIBILITY_STRINGS.each do |number, strings|
          return number if strings.include?(entry)
        end

        nil
      end
    end

    class GenresAttribute < FromGenreColumnAttributeBase
      def parse
        return nil unless columns[:genres]

        all_genres(columns) - VisibilityAttribute::VISIBILITY_STRINGS.values.flatten
      end
    end

    # Not an item attribute; only shares common behavior across the below
    # attribute parsers.
    class NotesAttributeBase < Attribute
      def split_notes(column_name, columns)
        return nil unless columns[column_name]

        columns[column_name]
          .presence
          &.chomp
          &.sub(/#{@config.deep_fetch(:csv, :long_separator).rstrip}\s*\z/, "")
          &.split(@config.deep_fetch(:csv, :long_separator))
      end
    end

    class PublicNotesAttribute < NotesAttributeBase
      def parse
        split_notes(:public_notes, columns)
      end
    end

    class BlurbAttribute < Attribute
      def parse
        return nil unless columns[:blurb]

        columns[:blurb]
          .presence
          &.chomp
      end
    end

    class PrivateNotesAttribute < NotesAttributeBase
      def parse
        split_notes(:private_notes, columns)
      end
    end
  end
end
