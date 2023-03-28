require_relative "util/hash_deep_merge"
require_relative "util/hash_array_deep_fetch"
require_relative "errors"

module Reading
  # Builds a hash config.
  class Config
    using Util::HashDeepMerge
    using Util::HashArrayDeepFetch

    attr_reader :hash

    # @param custom_config [Hash] a custom config which overrides the defaults,
    #   e.g. { enabled_columns: %i[head end_dates] }
    def initialize(custom_config = {})
      @custom_config = custom_config

      build_hash
    end

    private

    # Builds a hash of the default config combined with the given custom config.
    # @return [Hash]
    def build_hash
      @hash = default_config.deep_merge(@custom_config)

      # If custom formats are given, use only the custom formats.
      if @custom_config.has_key?(:formats)
        @hash[:formats] = @custom_config[:formats]
      end

      # Ensure enabled_columns includes :head, and sort them.
      enabled_columns =
        (@hash.fetch(:enabled_columns) + [:head])
        .uniq
        .sort_by { |col| default_config[:enabled_columns].index(col) || 0 }

      invalid_columns = enabled_columns - default_config[:enabled_columns]
      if invalid_columns.any?
        raise ConfigError, "Invalid columns in custom config: #{invalid_columns.join(", ")}"
      end

      @hash[:enabled_columns] = enabled_columns

      # Add the regex config, which is built based on the config so far.
      @hash[:regex] = regex_config
    end

    # The default config, excluding Regex config (see further down).
    # @return [Hash]
    def default_config
      {
        comment_character:        "\\",
        column_separator:         "|",
        ignored_characters:       "✅💲❓⏳",
        skip_compact_planned:     false,
        # The Head column is always enabled; the others can be disabled by
        # using a custom config that omits columns from this array.
        enabled_columns:
          %i[
            rating
            head
            sources
            start_dates
            end_dates
            genres
            length
            notes
            history
          ],
        # If your custom config includes formats, they will replace the defaults
        # (unlike the rest of the config, to which custom config is deep merged).
        # So if you want to keep any of these defaults, include them in your config.
        formats:
          {
            print:     "📕",
            ebook:     "⚡",
            audiobook: "🔊",
            pdf:       "📄",
            audio:     "🎤",
            video:     "🎞️",
            course:    "🏫",
            piece:     "✏️",
            website:   "🌐",
          },
        sources:
          {
            names_from_urls:
              {
                "youtube.com"         => "YouTube",
                "youtu.be"            => "YouTube",
                "books.google.com"    => "Google Books",
                "archive.org"         => "Internet Archive",
                "thegreatcourses.com" => "The Great Courses",
                "librivox.org"        => "LibriVox",
                "tv.apple.com"        => "Apple TV",
              },
            default_name_for_url: "site",
          },
        # The structure of an item, along with default values.
        # Wherever an array of hashes ends up with no data (i.e. equal to the
        # value in the template), it is collapsed into an empty array.
        # E.g. the row "|Dracula||🤝🏼book club" is parsed to a Struct analogous to:
        # {
        #   rating: nil,
        #   author: nil,
        #   title: "Dracula",
        #   genres: [],
        #   variants: [],
        #   experiences: [{ spans: [], group: "book club", variant_index: 0 }],
        #   notes: [],
        # }
        item_template:
          {
            rating: nil,
            author: nil,
            title: nil,
            genres: [],
            variants:
              [{
                format: nil,
                series:
                  [{
                    name: nil,
                    volume: nil,
                  }],
                sources:
                  [{
                    name: nil,
                    url: nil,
                  }],
                isbn: nil,
                length: nil,
                extra_info: [],
              }],
            experiences:
              [{
                spans:
                  [{
                    dates: nil,
                    amount: nil,
                    progress: nil,
                    name: nil,
                    favorite?: false,
                  }],
                group: nil,
                variant_index: 0,
              }],
            notes:
              [{
                blurb?: false,
                private?: false,
                content: nil,
              }],
          },
      }
    end

    # Builds the regex portion of the config, based on the config so far.
    # @return [Hash]
    def regex_config
      return @hash[:regex] if @hash.has_key?(:regex)

      formats = @hash.fetch(:formats).values.join("|")

      {
        formats: /#{formats}/,
        formats_split: /\s*(?:,|--)?\s*(?=#{formats})/,
      }
    end
  end
end
