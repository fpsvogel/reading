module Reading
  class Item
    # A view object for an Item, providing shortcuts to information that is handy
    # to show (for example) on a webpage.
    class View
      using Util::HashArrayDeepFetch

      attr_reader :name, :rating, :type_emoji, :genres, :date_or_status,
        :isbn, :url, :experience_count, :groups, :blurb, :public_notes

      # @param item [Item] the Item from which to extract view information.
      def initialize(item)
        @genres = item.genres
        @rating = extract_star_or_rating(item)
        @isbn, @url, variant = extract_first_source_info(item)
        @name = extract_name(item, variant)
        @type_emoji = extract_type_emoji(variant&.format)
        @date_or_status = extract_date_or_status(item)
        @experience_count = item.experiences.count
        @groups = item.experiences.map(&:group).compact
        @blurb = item.notes.find(&:blurb?)&.content
        @public_notes = item.notes.reject(&:private?).reject(&:blurb?).map(&:content)
      end

      private

      # A star (or nil if the item doesn't make the cut), or the number rating if
      # star ratings are disabled.
      # @param item [Item]
      # @return [String, Integer, Float]
      def extract_star_or_rating(item)
        minimum_rating = Config.hash.deep_fetch(:item, :view, :minimum_rating_for_star)
        if minimum_rating
          "⭐" if item.rating && item.rating >= minimum_rating
        else
          item.rating
        end
      end


      # The ISBN/ASIN, URL, format, and extra info of the first variant that has
      # an ISBN/ASIN or URL. If an ISBN/ASIN is found first, it is used to build a
      # Goodreads URL. If a URL is found first, the ISBN/ASIN is nil.
      # @param item [Item]
      # @return [Array(String, String, Symbol, Array<String>)]
      def extract_first_source_info(item)
        item.variants.map { |variant|
          isbn = variant.isbn
          if isbn
            url = Config.hash.deep_fetch(:item, :view, :url_from_isbn).sub("%{isbn}", isbn)
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
      # @param variant [Data, nil] a variant from the Item.
      # @return [String]
      def extract_name(item, variant)
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

          name_separator = Config.hash.deep_fetch(:item, :view, :name_separator)
          series_and_extra_info = name_separator +
            (pretty_series + variant.extra_info).join(name_separator)
        end

        author_and_title + (series_and_extra_info || "")
      end

      # The emoji for the type that represents (encompasses) a given format.
      # @param format [Symbol, nil]
      # @return [String]
      def extract_type_emoji(format)
        types = Config.hash.deep_fetch(:item, :view, :types)

        return types.deep_fetch(format, :emoji) if types.has_key?(format)

        type = types
          .find { |type, hash| hash[:from_formats]&.include?(format) }
          &.first # key

        types.deep_fetch(
          type || Config.hash.deep_fetch(:item, :view, :default_type),
          :emoji,
        )
      end

      # The date (if done) or status, stringified.
      # @param item [Item]
      # @return [String]
      def extract_date_or_status(item)
        if item.done?
          item.last_end_date&.strftime("%Y-%m-%d")
        else
          item.status.to_s.gsub("_", " ")
        end
      end
    end
  end
end
