module Reading
  class Item
    # A view object for an Item, providing shortcuts to information that is handy
    # to show (for example) on a webpage.
    class View
      using Util::HashArrayDeepFetch

      attr_reader :name, :rating, :type_emoji, :genres, :status, :date, :date_in_words,
        :isbn, :url, :experience_count, :groups, :blurb, :public_notes

      # @param item [Item] the Item from which to extract view information.
      # @param config [Hash] an entire config.
      def initialize(item, config)
        @genres = item.genres
        @status = item.status.to_s.gsub('_', ' ')
        @rating = extract_star_or_rating(item, config)
        @isbn, @url, variant = extract_first_source_info(item, config)
        @name = extract_name(item, variant, config)
        @type_emoji = extract_type_emoji(variant&.format, config)
        @date = item.experiences.last&.spans&.last&.dates&.end&.strftime("%Y-%m-%d")
        @experience_count = item.experiences.count
        @groups = item.experiences.map(&:group).compact
        @blurb = item.notes.find(&:blurb?)&.content
        @public_notes = item.notes.reject(&:private?).reject(&:blurb?).map(&:content)
      end

      private

      # A star (or nil if the item doesn't make the cut), or the number rating if
      # star ratings are disabled.
      # @param item [Item]
      # @param config [Hash] an entire config.
      # @return [String, Integer, Float]
      def extract_star_or_rating(item, config)
        minimum_rating = config.deep_fetch(:item_view, :minimum_rating_for_star)
        if minimum_rating
          "⭐" if item.rating >= minimum_rating
        else
          item.rating
        end
      end


      # The ISBN/ASIN, URL, format, and extra info of the first variant that has
      # an ISBN/ASIN or URL. If an ISBN/ASIN is found first, it is used to build a
      # Goodreads URL. If a URL is found first, the ISBN/ASIN is nil.
      # @param item [Item]
      # @param config [Hash] an entire config.
      # @return [Array(String, String, Symbol, Array<String>)]
      def extract_first_source_info(item, config)
        item.variants.map { |variant|
          isbn = variant.isbn
          if isbn
            url = config.deep_fetch(:item_view, :url_from_isbn).sub('%{isbn}', isbn)
          else
            url = variant.sources.map { |source| source.url }.compact.first
          end

          [isbn, url, variant]
        }
        .select { |isbn, url, _variant| isbn || url }
        .first || [nil, nil, item.variants.first]
      end

      # The view name of the item.
      # @param item [Item]
      # @param variant [Struct, nil] a variant from the Item.
      # @param config [Hash] an entire config.
      # @return [String]
      def extract_name(item, variant, config)
        author_and_title = "#{item.author + " – " if item.author}#{item.title}"
        return author_and_title if variant.nil?

        unless variant.series.empty? && variant.extra_info.empty?
          pretty_series = variant.series.map { |series|
            if series.volume
              "#{series.name}, ##{series.volume}"
            else
              "in #{series.name}"
            end
          }

          name_separator = config.deep_fetch(:item_view, :name_separator)
          series_and_extra_info = name_separator +
            (pretty_series + variant.extra_info).join(name_separator)
        end

        author_and_title + (series_and_extra_info || "")
      end

      # The emoji for the type that represents (encompasses) a given format.
      # @param format [Symbol, nil]
      # @param config [Hash] an entire config.
      # @return [String]
      def extract_type_emoji(format, config)
        types = config.deep_fetch(:item_view, :types)

        return types.deep_fetch(format, :emoji) if types.has_key?(format)

        type = types
          .find { |type, hash| hash[:from_formats]&.include?(format) }
          &.first # key

        types.deep_fetch(
          type || config.deep_fetch(:item_view, :default_type),
          :emoji,
        )
      end
    end
  end
end
