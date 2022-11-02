require_relative "../util/deep_fetch"
require_relative "../util/deep_merge"

module Reading
  using Util::DeepFetch
  using Util::DeepMerge

  # Builds a hash of the default config combined with the given custom config.
  # @param custom_config [Hash] a custom config which overrides the defaults,
  #   e.g. { errors: { styling: :html } }
  # @return [Hash]
  def self.build_config(custom_config = {})
    config = @default_config.deep_merge(custom_config)

    # If custom formats are given, use only the custom formats. #dig is used here
    # (not #deep_fetch as most elsewhere) because custom_config may not include this data.
    if custom_config[:item] && custom_config.dig(:item, :formats)
      config[:item][:formats] = custom_config.dig(:item, :formats)
    end

    # Name column can't be disabled.
    config.deep_fetch(:csv, :columns)[:name] = true

    # Add the Regex config, which is built based on the config so far.
    config[:csv][:regex] = build_regex_config(config)

    config
  end

  # The default config, excluding Regex config (see further down).
  @default_config =
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
              series:
                [{
                  name: nil,
                  volume: nil,
                }],
              variants:
                [{
                  format: nil,
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
                  date_added: nil,
                  spans:
                    [{
                      dates: nil,
                      amount: nil,
                      description: nil,
                    }],
                  progress: nil,
                  group: nil,
                  variant_index: 0,
                }],
              visibility: 3, # TODO use a constant here.
              genres: [],
              public_notes: [],
              blurb: nil,
              private_notes: [],
            },
        },
      csv:
        {
          path:               nil, # Set if you want to load a local file.
          columns:
            {
              rating:         true,
              name:           true, # always enabled
              sources:        true,
              dates_started:  true,
              dates_finished: true,
              genres:         true,
              length:         true,
              public_notes:   true,
              blurb:          true,
              private_notes:  true,
              history:        true,
            },
          # Custom columns are listed in a hash with default values, like simple columns in item[:template] above.
          custom_numeric_columns:   {}, # e.g. { family_friendliness: 5, surprise_factor: nil }
          custom_text_columns:      {}, # e.g. { mood: nil, rec_by: nil, will_reread: "no" }
          comment_character:        "\\",
          column_separator:         "|",
          separator:                ",",
          short_separator:          " - ",
          long_separator:           " -- ",
          date_separator:           "/",
          dnf_string:               "DNF",
          series_prefix:            "in",
          group_emoji:              "🤝🏼",
          compact_planned_source_prefix: "@",
          reverse_dates:            false,
          skip_compact_planned:     false,
        },
    }

  # Builds the Regex portion of the config, based on the given config.
  # @param other_config [Hash] the rest of the config, i.e. @default_config
  #   overriden by any custom config.
  # @return [Hash]
  private_class_method def self.build_regex_config(other_config)
    return other_config[:csv][:regex] if other_config.dig(:csv, :regex)

    comment_character = Regexp.escape(other_config.deep_fetch(:csv, :comment_character))
    formats = /#{other_config.deep_fetch(:item, :formats).values.join("|")}/
    dnf_string = Regexp.escape(other_config.deep_fetch(:csv, :dnf_string))
    date_sep = Regexp.escape(other_config.deep_fetch(:csv, :date_separator))
    date_regex = /(\d{4}#{date_sep}\d?\d#{date_sep}\d?\d)/ # TODO hardcode the date separator?
    time_length = /(\d+:\d\d)/
    pages_length = /p?(\d+)p?/

    {
      comment_escaped: comment_character,
      compact_planned_row_start: /\A\s*#{comment_character}(?<genre>[^a-z:,\|]+):\s*(?=#{formats})/,
      compact_planned_item: /\A(?<first_format_emojis>(?:#{formats})+)(?<author_title>[^@]+)(?<sources>@.+)?\z/,
      compact_planned_source: /\A(?<format_emojis>(?:#{formats})*)(?<source_name>.+)\z/,
      formats: formats,
      formats_split: /\s*,\s*(?=#{formats})/,
      series_volume: /,\s*#(\d+)\z/,
      isbn: isbn_regex(other_config),
      sources: sources_regex(other_config),
      date_added: /#{date_regex}.*>/,
      date_started: /#{date_regex}[^>]*\z/,
      dnf: /(?<=>|\A)\s*(#{dnf_string})/,
      progress: /(?<=#{dnf_string}|>|\A)\s*((\d?\d)%|#{time_length}|#{pages_length})\s+/,
      group_experience: /#{other_config.deep_fetch(:csv, :group_emoji)}\s*(.*)\s*\z/,
      variant_index: /\s+v(\d+)/,
      date_finished: date_regex,
      time_length: time_length,
      pages_length: pages_length,
      pages_length_in_variant: /(?:\A|\s+|p)(\d{1,9})(?:p|\s+|\z)/, # to exclude ISBN-10 and ISBN-13
    }
  end

  # Builds the Regex for item ISBN/ASIN.
  private_class_method def self.isbn_regex(other_config)
    return @isbn_regex unless @isbn_regex.nil?

    isbn_lookbehind = "(?<=\\A|\\s|#{other_config.deep_fetch(:csv, :separator)})"
    isbn_lookahead = "(?=\\z|\\s|#{other_config.deep_fetch(:csv, :separator)})"
    isbn_bare_regex = /(?:\d{3}[-\s]?)?[A-Z\d]{10}/ # also includes ASIN

    @isbn_regex = /#{isbn_lookbehind}#{isbn_bare_regex.source}#{isbn_lookahead}/
  end

  # Builds the Regex for item sources.
  private_class_method def self.sources_regex(other_config)
    return @sources_regex unless @sources_regex.nil?

    isbn = "(#{isbn_regex(other_config).source})"
    url_name = "([^#{other_config.deep_fetch(:csv, :separator)}]+)"
    url = "(https?://[^\\s#{other_config.deep_fetch(:csv, :separator)}]+)"
    url_prename = "#{url_name}#{other_config.deep_fetch(:csv, :short_separator)}#{url}"
    url_postname = "#{url}#{other_config.deep_fetch(:csv, :short_separator)}#{url_name}"

    @sources_regex = /#{isbn}|#{url_prename}|#{url_postname}|#{url}/
  end
end
