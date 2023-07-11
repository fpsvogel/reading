require_relative 'errors'

module Reading
  # Builds a hash config.
  class Config
    using Util::HashDeepMerge
    using Util::HashArrayDeepFetch

    attr_reader :hash

    # Builds an entire config hash from a custom config hash (which is typically
    # not an entire config, but it can be, in which case a copy is returned).
    # @param custom_config [Hash, Config]
    # @return [Hash]
    def self.hash(custom_config = {})
      new(custom_config).hash
    end

    # @param custom_config [Hash] a custom config which overrides the defaults,
    #   e.g. { enabled_columns: [:head, :end_dates] }
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
        ignored_characters:       "✅❌💲❓⏳",
        skip_compact_planned:     false,
        pages_per_hour:           35,
        speed: # e.g. listening speed for audiobooks and podcasts.
          {
            format:
              {
                audiobook: 1.0,
                audio: 1.0,
              },
          },
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
        source_names_from_urls:
          {
            "audible.com"         => "Audible",
            "youtube.com"         => "YouTube",
            "youtu.be"            => "YouTube",
            "books.google.com"    => "Google Books",
            "archive.org"         => "Internet Archive",
            "thegreatcourses.com" => "The Great Courses",
            "librivox.org"        => "LibriVox",
            "tv.apple.com"        => "Apple TV",
          },
        item:
          {
            # After how many days of no activity an item of indefinite length
            # (e.g. a podcast) should change its status from :in_progress to :done.
            indefinite_in_progress_grace_period_days: 30,
            view:
              {
                name_separator: " 〜 ",
                url_from_isbn: "https://www.goodreads.com/book/isbn?isbn=%{isbn}",
                # Items rated this or above get a star. If nil, number ratings are shown instead.
                minimum_rating_for_star: 5,
                types:
                  {
                    book: { emoji: "📕", from_formats: %i[print ebook audiobook pdf] },
                    course: { emoji: "🏫", from_formats: %i[website] },
                    piece: { emoji: "✏️" },
                    video: { emoji: "🎞️" },
                    audio: { emoji: "🎤" },
                  },
                default_type: :book,
              },
            # The structure of an item, along with default values.
            # Wherever an array of hashes ends up with no data (i.e. equal to the
            # value in the template), it is collapsed into an empty array.
            # E.g. the row "|Dracula||🤝🏼book club" is parsed to an Item analogous to:
            # {
            #   rating: nil,
            #   author: nil,
            #   title: "Dracula",
            #   genres: [],
            #   variants: [],
            #   experiences: [{ spans: [], group: "book club", variant_index: 0 }],
            #   notes: [],
            # }
            template:
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
                        progress: 1.0,
                        amount: 0,
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
