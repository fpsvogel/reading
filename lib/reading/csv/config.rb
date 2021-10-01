# frozen_string_literal: true

module Reading
  def self.config
    @config
  end

  @config =
  {
    errors:
      {
        handle_error:             -> (error) { puts error },
        max_length:               (IO.console.winsize[1] if IO.respond_to?(:console)) ||
                                    100,
        catch_all_errors:         true, # set this to false during development.
        style_mode:               :terminal # or :html
      },
    item:
      {
        formats:                { print:      "📕",
                                  ebook:      "⚡",
                                  audiobook:  "🔊",
                                  pdf:        "📄",
                                  audio:      "🎤",
                                  video:      "🎞️",
                                  course:     "🏫",
                                  article:    "📰",
                                  website:    "🌐" },
        sources:
         {
           names_from_urls:     { "youtube.com" => "YouTube",
                                  "youtu.be" => "YouTube",
                                  "books.google.com" => "Google Books",
                                  "archive.org" => "Internet Archive",
                                  "lexpublib.org" => "Lexington Public Library",
                                  "tv.apple.com" => "Apple TV" },
          default_name_for_url: "site"
         },
        template:               { rating: nil,
                                  author: nil,
                                  title: nil,
                                  series: [{ name: nil,
                                             volume: nil }],
                                  variants:    [{ format: nil,
                                                  sources: [{ name: nil,
                                                              url: nil }],
                                                  isbn: nil,
                                                  length: nil,
                                                  extra_info: [] }],
                                  experiences: [{ date_added: nil,
                                                  date_started:  nil,
                                                  date_finished: nil,
                                                  progress: nil,
                                                  group: nil,
                                                  variant_id: 0 }],
                                  visibility: 3,
                                  genres: [],
                                  public_notes: [],
                                  blurb: nil,
                                  private_notes: [],
                                  history: [] },
      },
    csv:
      {
        path:                     nil, # set if you want to load a local file.
        # for selective sync; the default (this) is to continue in all cases.
        selective_continue:       -> (last_parsed_data) { true },
        columns:                { rating:         true,
                                  name:           true, # always enabled
                                  sources:        true,
                                  dates_started:  true,
                                  dates_finished: true,
                                  genres:         true,
                                  length:         true,
                                  public_notes:   true,
                                  blurb:          true,
                                  private_notes:  true,
                                  history:        true },
        custom_columns:         {},
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
        reverse_dates:            false
      }
  }

  class << self
    private

    def add_regex_config
      return config[:csv][:regex] unless config[:csv][:regex].nil?
      comment_character = Regexp.escape(config.fetch(:csv).fetch(:comment_character))

      formats = /#{config.fetch(:item).fetch(:formats).values.join("|")}/
      dnf_string = Regexp.escape(config.fetch(:csv).fetch(:dnf_string))
      date_sep = Regexp.escape(config.fetch(:csv).fetch(:date_separator))
      date_regex = /(\d{4}#{date_sep}\d?\d#{date_sep}\d?\d)/ # TODO hardcode the date separator?
      time_length = /(\d+:\d\d)/
      pages_length = /p?(\d+)p?/
      config[:csv][:regex] =
        {
          comment_escaped: comment_character,
          compact_planned_line_start: /\A\s*#{comment_character}(?<genre>[^a-z:,\|]+):\s*(?=#{formats})/,
          compact_planned_item: /\A(?<format_emojis>(?:#{formats})+)(?<author_title>[^@]+)(?<sources>@.+)?\z/,
          formats: formats,
          formats_split: /\s*(?=#{formats})/,
          series_volume: /,\s*#(\d+)\z/,
          isbn: isbn_regex,
          sources: sources_regex,
          date_added: /#{date_regex}.*>/,
          date_started: /#{date_regex}[^>]*\z/,
          dnf: /(?<=>|\A)\s*(#{dnf_string})/,
          progress: /(?<=#{dnf_string}|>|\A)\s*((\d?\d)%|#{time_length}|#{pages_length})\s+/,
          group_experience: /#{config.fetch(:csv).fetch(:group_emoji)}\s*(.*)\s*\z/,
          variant_id: /\s+v(\d+)/,
          date_finished: date_regex,
          time_length: time_length,
          pages_length: pages_length,
          pages_length_in_variant: /(?:\A|\s+|p)(\d{1,9})(?:p|\s+|\z)/ # to exclude ISBN-10 and ISBN-13
        }
    end

    def isbn_regex
      return @isbn_regex unless @isbn_regex.nil?
      isbn_lookbehind = "(?<=\\A|\\s|#{config.fetch(:csv).fetch(:separator)})"
      isbn_lookahead = "(?=\\z|\\s|#{config.fetch(:csv).fetch(:separator)})"
      isbn_bare_regex = /(?:\d{3}[-\s]?)?[A-Z\d]{10}/ # also includes ASIN
      @isbn_regex = /#{isbn_lookbehind}#{isbn_bare_regex.source}#{isbn_lookahead}/
    end

    def sources_regex
      return @sources_regex unless @sources_regex.nil?
      isbn = "(#{isbn_regex.source})"
      url_name = "([^#{config.fetch(:csv).fetch(:separator)}]+)"
      url = "(https?://[^\\s#{config.fetch(:csv).fetch(:separator)}]+)"
      url_prename = "#{url_name}#{config.fetch(:csv).fetch(:short_separator)}#{url}"
      url_postname = "#{url}#{config.fetch(:csv).fetch(:short_separator)}#{url_name}"
      @sources_regex = /#{isbn}|#{url_prename}|#{url_postname}|#{url}/
    end
  end

  add_regex_config
end
