# frozen_string_literal: true

require_relative "util"
require_relative "errors"

module Reading
  module CSV
    using Blank

    # Load is a function that parses CSV lines into item data.
    class Load
      using HashToAttr
      attr_private :config_csv, :config_item, :cur_line

      def initialize(config_csv, config_item)
        config_csv.to_attr_private(self)
        @config_csv       = config_csv
        @config_item       = config_item
        @cur_line          = nil
      end

      # returns item data in the same order as they arrive from feed.
      # if no block is given, the raw data is returned.
      # if a block is given, the data is run through it, e.g. to create Items.
      def call(feed = nil, close_feed: true, err_block: nil, &data_postprocess_block)
        feed ||= File.open(path)
        items = []
        feed.each_line do |line|
          @cur_line = line.strip
          next if header? || comment? || blank_line?
          items += ParseLine.new(config_csv, config_item)
                            .call(cur_line, &data_postprocess_block)
        rescue InvalidLineError, ValidationError => e
          err_block&.call(e)
          next
        end
        items
      rescue Errno::ENOENT
        raise FileError.new(path, label: "File not found!")
      rescue Errno::EISDIR
        raise FileError.new(path, label: "The library must be a file, not a directory!")
      ensure
        feed&.close if close_feed && feed.respond_to?(:close)
        initialize(config_csv, config_item) # reset to pre-call state
      end

      private

      def header?
        cur_line.start_with?(header_first)
      end

      def comment?
        cur_line.start_with?(comment_mark)
      end

      def blank_line?
        cur_line.empty?
      end

      # ParseLine is a function that parses a line in a CSV reading library into
      # an array of item data (hashes), typically converted into Items.
      class ParseLine
        using HashToAttr
        attr_private :line, :formats_regex, :config_item
        attr_reader  :items

        def initialize(config_csv, config_item)
          config_csv.merge(config_item.slice(:formats)).to_attr_private(self)
          @formats_regex = formats.values.join("|")
          @config_item = config_item
        end

        # data_postprocess_block can be used to convert the hashes into Items.
        def call(line, raw_data: false, &data_postprocess_block)
          @line = line
          items = split_multi_names(columns[:name]).map.with_index do |name, i|
            data = parse_item_data(columns, name, config_item.fetch(:template))
            data = with_symbol_keys(data)
            if block_given?
              data_postprocess_block.call(data, line, i)
            else
              data
            end
          end.compact
          @line = nil
          items
        end

        private

        def with_symbol_keys(item_data)
          with_symbols = item_data.transform_keys(&:to_sym)
          with_symbols[:format] = with_symbols[:format]&.to_sym
          with_symbols
        end

        def columns
          return @columns unless @columns.nil?
          @columns = column_names
                      .zip(line.split(column_separator))
                      .to_h
          raise InvalidLineError.new(line) if any_important_columns_empty?(@columns)
          @columns
        end

        def any_important_columns_empty?(columns)
          columns.slice(*error_if_blank)
                 .values.any? { |col| col.nil? || col.strip.empty? }
        end

        def split_multi_names(names_column)
          names_column
            .split(/\s*(?=#{formats_regex})/)
            .map { |name| name.strip.sub(/[,;]\z/, "") }
            .partition { |name| name.match?(/\A#{formats_regex}/) }
            .reject(&:empty?).first
        end

        def parse_item_data(columns, name, template)
          template.map { |field, _default| [field, send(field, columns, name)] }
                  .to_h
        end

        def rating(columns, _=nil)
          rating = columns[:rating].strip
          return nil if rating.empty?
          Integer(rating, exception: false) \
            || Float(rating, exception: false) \
            || (raise InvalidLineError.new(line))
        end

        def format(_=nil, name)
          icon = name.match(/^#{formats_regex}/).to_s
          formats.key(icon)
        end

        def author(_=nil, name)
          name.sub(/^#{formats_regex}/, "")
              .match(/.+(?=#{author_separator})/)
              &.to_s
              &.strip
        end

        def title(_=nil, name)
          name.sub(/^#{formats_regex}/, "")
              .sub(/.+#{author_separator}/, "")
              .presence \
              || raise(InvalidLineError.new(line))
        end

        def isbn_or_asin_alone_regex
          @isbn_regex ||= /(?:\d{3}[-\s]?)?[A-Z\d]{10}/
        end

        def isbn_or_asin_regex
          return @isbn_or_asin_regex unless @isbn_or_asin_regex.nil?
          isbn_lookbehind = "(?<=\\A|\\s|#{separator})"
          isbn_lookahead = "(?=\\z|\\s|#{separator})"
          @isbn_or_asin_regex = /#{isbn_lookbehind}#{isbn_or_asin_alone_regex.source}#{isbn_lookahead}/
        end

        def isbn(columns, _=nil)
          isbns = columns[:sources].scan(isbn_or_asin_regex)
          raise InvalidLineError.new(line) if isbns.count > 1
          isbns[0]&.to_s
        end

        def isbns_and_urls_regex
          return @sources_regex unless @sources_regex.nil?
          isbn = "(#{isbn_or_asin_regex.source})"
          url_name = "([^#{separator}]+)"
          url = "(https?://[^\\s#{separator}]+)"
          url_prename = "#{url_name}#{source_name_separator}#{url}"
          url_postname = "#{url}#{source_name_separator}#{url_name}"
          @sources_regex = /#{isbn}|#{url_prename}|#{url_postname}|#{url}/
        end

        def sources(columns, _=nil)
          urls = columns[:sources]
                  .scan(isbns_and_urls_regex)
                  .map(&:compact)
                  .reject { |source| source.first.match? isbn_or_asin_regex }
          names = columns[:sources]
                    .gsub(isbns_and_urls_regex, separator)
                    .split(separator)
                    .reject { |name| name.strip.empty? }
          (urls << names).presence
        end

        def sources_separator
          if columns[:sources].include? separator
            separator
          else
            /(?<=[^-\s])\s+(?=[^-\s])/
          end
        end

        def perusals(columns, _=nil)
          started = dates_started(columns) || []
          finished, progresses_in_dates = dates_finished(columns) || [[], []]
          started_finished =
            started_padded(started, finished)
            .zip(finished)
            .map { |start, finish| { date_started: start, date_finished: finish } }
          added = { date_added: date_added(columns) }
          return [added] if started_finished.count.zero?
          date_perusals = started_finished.tap { |dates| dates.first.merge!(added) }
          merge_progresses(columns, date_perusals, progresses_in_dates)
        end

        def started_padded(started, finished)
          return started if started.count >= finished.count
          pad_length = finished.count - started.count
          started + ([nil] * pad_length)
        end

        def merge_progresses(columns, date_perusals, progresses_in_dates)
          if progresses_in_dates.compact.presence
            final_progresses = progresses_in_dates
            # DNF must not be indicated in the two columns at the same time.
            raise(InvalidLineError.new(line)) unless progress(columns[:name]).nil?
          else
            final_progresses = [progress(columns[:name])] * date_perusals.count
          end
          date_perusals.map.with_index do |dates, i|
            dates.merge({ progress: final_progresses[i] })
          end
        end

        def dnf_regex
          /\ADNF\s*(?:(?<progress>\d\d?)%\s*)?/
        end

        def progress(str)
          dnf = str.strip.match(dnf_regex)
          return nil if dnf.nil?
          return 0 if dnf[:progress].nil?
          dnf[:progress].to_i
        end

        def date_added(columns)
          return nil unless columns[:dates_started].strip.present?
          added = columns[:dates_started]
                  .match(/.+(?=#{date_added_separator})/)
                  &.to_s
                  &.then { |str| to_date_strings(str) }
          raise InvalidLine.new(line) if added && added.count > 1
          added&.first
        end

        def dates_started(columns)
          return nil unless columns[:dates_started].strip.present?
          columns[:dates_started]
            .sub(/.+#{date_added_separator}/, "")
            .then { |str| to_date_strings(str) }
        end

        def dates_finished(columns)
          return nil unless columns[:dates_finished].strip.present?
          progresses = []
          dates = to_date_strings(columns[:dates_finished]) do |raw_date|
            progresses << progress(raw_date)
            raw_date.strip.sub(dnf_regex, "")
          end
          [dates, progresses]
        end

        def to_date_strings(dates_str, &process_raw_date)
          dates_str.strip.split(/#{separator}\s*/).map do |date|
            date_hyphenated = date.gsub(date_separator, "-")
            process_raw_date&.call(date_hyphenated) || date_hyphenated
          end.presence
        end

        def genres(columns, _=nil)
          columns[:genres]
            .split(separator)
            .map(&:strip)
            .map(&:presence)
            .compact.presence
        end

        def length(columns, _=nil)
          len = columns[:length].strip
          len.match(/\d+:\d\d/).to_s.presence \
            || Integer(len, exception: false) \
            || raise(InvalidLineError.new(line))
        end

        def public_notes(columns, _=nil)
          columns[:public_notes]
            &.presence
            &.chomp
            &.sub(/#{notes_newline.rstrip}\z/, "")
            &.split(notes_newline)
        end

        def blurb(columns, _=nil)
          columns[:blurb]
            &.presence
            # &.gsub(notes_newline, "\n")
            &.chomp
            # &.sub(/#{notes_newline.chop}\z/, "")
        end

        def private_notes(columns, _=nil)
          columns[:private_notes]
            &.presence
            &.chomp
            &.sub(/#{notes_newline.rstrip}\z/, "")
            &.split(notes_newline)
        end

        def history(columns, _=nil)
          columns[:history]
        end
      end
    end
  end
end
