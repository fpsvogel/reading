require_relative "../../errors"
require_relative "../../util/blank"
require_relative "../../util/deep_fetch"
require_relative "parse_attribute"
require_relative "parse_variants"
require_relative "parse_experiences"

module Reading
  class CSV
    class ParseRow
      using Util::DeepFetch

      # The short attribute parsers are collected below. The longer attribute
      # parsers are separated into their own files.

      class ParseRating < ParseAttribute
        def call(_name = nil, columns)
          return nil unless columns[:rating]
          rating = columns[:rating].strip
          return nil if rating.empty?
          Integer(rating, exception: false) ||
            Float(rating, exception: false)
        end
      end

      class ParseAuthor < ParseAttribute
        def call(name, _columns = nil)
          name
            .sub(/\A#{@config.deep_fetch(:csv, :regex, :formats)}/, "")
            .match(/.+(?=#{@config.deep_fetch(:csv, :short_separator)})/)
            &.to_s
            &.strip
        end
      end

      class ParseTitle < ParseAttribute
        def call(name, _columns = nil)
          name
            .sub(/\A#{@config.deep_fetch(:csv, :regex, :formats)}/, "")
            .sub(/.+#{@config.deep_fetch(:csv, :short_separator)}/, "")
            .sub(/#{@config.deep_fetch(:csv, :long_separator)}.+\z/, "")
            .strip
            .presence
        end
      end

      class ParseSeries < ParseAttribute
        def call(name, _columns = nil)
          separated = name
            .split(@config.deep_fetch(:csv, :long_separator))
            .map(&:strip)
            .map(&:presence)
            .compact
          separated.delete_at(0) # everything before the series/extra info
          separated.map { |str|
            volume = str.match(@config.deep_fetch(:csv, :regex, :series_volume))
            prefix = "#{@config.deep_fetch(:csv, :series_prefix)} "
            if volume || str.start_with?(prefix)
              { name: str.delete_suffix(volume.to_s).delete_prefix(prefix) || default[:name],
                volume: volume&.captures&.first&.to_i                      || default[:volume] }
            end
          }
          .compact.presence
        end

        def default
          @config.deep_fetch(:item, :template, :series).first
        end
      end

      # Not an item attribute; only shares common behavior across the below
      # attribute parsers.
      class ParseFromGenreColumn < ParseAttribute
        @@all_genres = nil

        def all_genres(columns)
          @@all_genres ||= columns[:genres]
            .split(@config.deep_fetch(:csv, :separator))
            .map(&:strip)
            .map(&:presence)
            .compact.presence
        end
      end

      # TODO make Parse___ officially stateful (resets state after a row is
      # parsed) so that the Genres column doesn't have this hacky state where
      # ParseGenres resets state because it's called after ParseVisibility.
      # this is order-dependent, requiring that :visibility appear before
      # :genres in the item template.
      class ParseVisibility < ParseFromGenreColumn
        VISIBILITY_STRINGS =
          { 0 => ["private", "for me", "to me", "for-me", "to-me"],
            1 => ["for starred friends", "to starred friends",
                  "for-starred-friends", "to-starred-friends",
                  "for starred", "to starred", "for-starred", "to-starred"],
            2 => ["for friends", "to friends", "for-friends", "to-friends"]
          }

        def call(_name = nil, columns)
          return nil unless columns[:genres]
          visibility = @config.deep_fetch(:item, :template, :visibility)
          all_genres(columns).each do |entry|
            if specified_visibility = visibility_string_to_number(entry)
              visibility = specified_visibility
              @@all_genres.delete(entry)
              break
            end
          end
          visibility
        end

        def visibility_string_to_number(entry)
          VISIBILITY_STRINGS.each do |number, strings|
            return number if strings.include?(entry)
          end
          nil
        end
      end

      class ParseGenres < ParseFromGenreColumn
        def call(_name = nil, columns)
          return nil unless columns[:genres]
          genres = @@all_genres # Visibility has already been taken out by ParseVisibility.
          @@all_genres = nil
          genres
        end
      end

      # Not an item attribute; only shares common behavior across the below
      # attribute parsers.
      class ParseNotesAttribute < ParseAttribute
        def split_notes(column_name, columns)
          return nil unless columns[column_name]
          columns[column_name]
            .presence
            &.chomp
            &.sub(/#{@config.deep_fetch(:csv, :long_separator).rstrip}\s*\z/, "")
            &.split(@config.deep_fetch(:csv, :long_separator))
        end
      end

      class ParsePublicNotes < ParseNotesAttribute
        def call(_name = nil, columns)
          split_notes(:public_notes, columns)
        end
      end

      class ParseBlurb < ParseAttribute
        def call(_name = nil, columns)
          return nil unless columns[:blurb]
          columns[:blurb]
            .presence
            &.chomp
        end
      end

      class ParsePrivateNotes < ParseNotesAttribute
        def call(_name = nil, columns)
          split_notes(:private_notes, columns)
        end
      end
    end
  end
end
