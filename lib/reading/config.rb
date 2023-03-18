module Reading
  # Builds a hash config.
  class Config
    using Util::HashDeepMerge
    using Util::HashArrayDeepFetch

    attr_reader :hash

    # @param custom_config [Hash] a custom config which overrides the defaults,
    #   e.g. { errors: { styling: :html } }
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

      # Validate enabled_columns
      enabled_columns =
        (@hash.fetch(:enabled_columns) + [:head])
        .uniq
        .sort_by { |col| default_config[:enabled_columns].index(col) }

      # Add the Regex config, which is built based on the config so far.
      @hash[:regex] = build_regex_config
    end

    # The default config, excluding Regex config (see further down).
    # @return [Hash]
    def default_config
      {
        comment_character:        "\\",
        column_separator:         "|",
        ignored_chars:            "✅💲❓⏳⭐",
        skip_compact_planned:     false,
        # The Head column is always enabled; the others can be disabled by
        # using a custom config that omits columns from this array.
        enabled_columns:
          %i[
            rating
            head
            sources
            dates_started
            dates_finished
            genres
            length
            notes
            history
          ],
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

    # Builds the Regex portion of the config, based on the given config.
    # @return [Hash]
    def build_regex_config
      return @hash[:regex] if @hash.has_key?(:regex)

      formats = @hash.fetch(:formats).values.join("|")

      {
        formats: /#{formats}/,
        formats_split: /\s*(?:,|--)?\s*(?=#{formats})/,
      }
    end
  end
end
