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

      # If custom formats are given, use only the custom formats. #dig is used here
      # (not #deep_fetch as most elsewhere) because custom_config may not include this data.
      if @custom_config[:item] && @custom_config.dig(:item, :formats)
        @hash[:item][:formats] = @custom_config.dig(:item, :formats)
      end

      # Validate enabled_columns
      enabled_columns = @hash.deep_fetch(:csv, :enabled_columns)
      enabled_columns << :head
      enabled_columns.uniq!
      enabled_columns.sort_by! { |col| default_config.deep_fetch(:csv, :enabled_columns).index(col) }

      # Add the Regex config, which is built based on the config so far.
      @hash[:csv][:regex] = build_regex_config
    end

    # The default config, excluding Regex config (see further down).
    # @return [Hash]
    def default_config
      {
        errors:
          {
            handle_error:     -> (error) { puts error },
            max_length:       100, # or require "io/console", then IO.console.winsize[1]
            catch_all_errors: false, # set this to false during development.
            styling:          :terminal, # or :html
          },
        item:
          {
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
          },
        csv:
          {
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
                public_notes
                blurb
                private_notes
                history
              ],
            # Custom columns are listed in a hash with default values, like simple columns in item[:template] above.
            custom_numeric_columns:   {}, # e.g. { family_friendliness: 5, surprise_factor: nil }
            custom_text_columns:      {}, # e.g. { mood: nil, rec_by: nil, will_reread: "no" }
            comment_character:        "\\",
            column_separator:         "|",
            separator:                ",",
            short_separator:          " - ",
            long_separator:           " -- ",
            dnf_string:               "DNF",
            series_prefix:            "in",
            group_emoji:              "🤝🏼",
            blurb_emoji:              "💬",
            private_emoji:            "🔒",
            compact_planned_source_prefix: "@",
            compact_planned_ignored:  "✅💲❓⏳⭐",
            skip_compact_planned:     false,
          },
      }
    end

    # Builds the Regex portion of the config, based on the given config.
    # @return [Hash]
    def build_regex_config
      return @hash[:csv][:regex] if @hash.dig(:csv, :regex)

      comment_character = Regexp.escape(@hash.deep_fetch(:csv, :comment_character))
      formats = @hash.deep_fetch(:item, :formats).values.join("|")
      dnf_string = Regexp.escape(@hash.deep_fetch(:csv, :dnf_string))
      compact_planned_ignored = (
        @hash.deep_fetch(:csv, :compact_planned_ignored).chars - [" "]
      ).join("|")
      time_length = /(?<time>\d+:\d\d)/
      pages_length = /p?(?<pages>\d+)p?/
      url = /https?:\/\/[^\s#{@hash.deep_fetch(:csv, :separator)}]+/

      isbn_lookbehind = "(?<=\\A|\\s|#{@hash.deep_fetch(:csv, :separator)})"
      isbn_lookahead = "(?=\\z|\\s|#{@hash.deep_fetch(:csv, :separator)})"
      isbn_bare_regex = /(?:\d{3}[-\s]?)?[A-Z\d]{10}/ # also includes ASIN
      isbn = /#{isbn_lookbehind}#{isbn_bare_regex.source}#{isbn_lookahead}/

      {
        compact_planned_row_start: /\A\s*#{comment_character}\s*(?:(?<genres>[^a-z@:\|]+)?\s*(?<sources>@[^\|]+)?\s*:)?\s*(?=#{formats})/,
        compact_planned_item: /\A(?<format_emoji>(?:#{formats}))(?<author_title>[^@\|]+)(?<sources>@.+)?(?:\|(?<sources_column>.+))?\z/,
        formats: /#{formats}/,
        formats_split: /\s*(?:,|--)?\s*(?=#{formats})/,
        compact_planned_ignored: /#{compact_planned_ignored}/,
        series_volume: /,\s*#(\d+)\z/,
        isbn: isbn,
        url: url,
        dnf: /\A\s*(#{dnf_string})/,
        progress: /(?<=#{dnf_string}|\A)\s*(?:(?<percent>\d?\d)%|#{time_length}|#{pages_length})\s+/,
        group_experience: /#{@hash.deep_fetch(:csv, :group_emoji)}\s*(.*)\s*\z/,
        variant_index: /\s+v(\d+)/,
        date: /\d{4}\/\d?\d\/\d?\d/,
        time_length: /\A#{time_length}(?<each>\s+each)?\z/,
        time_length_in_variant: time_length,
        pages_length: /\A#{pages_length}(?<each>\s+each)?\z/,
        pages_length_in_variant: /(?:\A|\s+|p)(?<pages>\d{1,9})(?:p|\s+|\z)/, # to exclude ISBN-10 and ISBN-13
      }
    end
  end
end
