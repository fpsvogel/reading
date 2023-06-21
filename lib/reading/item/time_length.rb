module Reading
  class Item
    # The length of an item when it is a time, as opposed to pages. (Pages are
    # represented simply with an Integer or Float.)
    class Item::TimeLength
      include Comparable

      attr_reader :value # in total minutes

      private attr_reader :pages_per_hour

      # @param value [Numeric] the total minutes
      # @param pages_per_hour [Integer]
      def initialize(value, pages_per_hour:)
        @value = value
        @pages_per_hour = pages_per_hour
      end

      # Builds an Item::TimeLength from a string.
      # @param string [String] a time duration in "h:mm" format.
      # @param pages_per_hour [Integer]
      # @return [TimeLength, nil]
      def self.parse(string, pages_per_hour:)
        return nil unless string.match? /\A\d+:\d\d\z/

        hours, minutes = string.split(':').map(&:to_i)
        new((hours * 60) + minutes, pages_per_hour:)
      end

      # Builds an Item::TimeLength based on a page count.
      # @param pages [Integer, Float]
      # @return [TimeLength]
      def self.from_pages(pages, pages_per_hour:)
        new(pages_to_minutes(pages, pages_per_hour:), pages_per_hour:)
      end

      # Converts a page count to minutes.
      # @param pages [Integer, Float]
      # @return [Integer]
      def self.pages_to_minutes(pages, pages_per_hour:)
        (pages.to_f / pages_per_hour * 60)
      end

      # Only the hours, e.g. the "h" value in "h:mm".
      # @return [Numeric]
      def hours
        value.to_i / 60
      end

      # Only the hours, e.g. the "mm" value in "h:mm".
      # @return [Numeric]
      def minutes
        value % 60
      end

      # A string in "h:mm" format.
      # @return [String]
      def to_s
        "#{hours}:#{minutes.round.to_s.rjust(2, '0')} or #{(value / 60.0 * pages_per_hour).round} pages"
      end

      # @return [Boolean]
      def zero?
        value.zero?
      end

      # A copy of self with a rounded @value.
      # @return [TimeLength]
      def round
        self.class.new(@value.round, pages_per_hour:)
      end

      # Converts @value to an Integer if it's a whole number, and returns self.
      # @return [TimeLength]
      def to_i_if_whole!
        if @value.to_i == @value
          @value = @value.to_i
        end

        self
      end

      # A non-mutating version of #to_i_if_whole! for compatibility with the
      # refinement Numeric#to_i_if_whole.
      # @return [TimeLength]
      def to_i_if_whole
        return self if @value.is_a?(Integer) || @value.to_i != @value

        self.class.new(@value.to_i, pages_per_hour:)
      end

      # @param other [TimeLength, Numeric]
      # @return [TimeLength]
      def +(other)
        if other.is_a? Item::TimeLength
          self.class.new(value + other.value, pages_per_hour:)
        elsif other.is_a? Numeric
          self.class.new(
            value + self.class.pages_to_minutes(other, pages_per_hour:),
            pages_per_hour:,
          )
        else
          raise TypeError, "#{other.class} can't be added to Item::TimeLength."
        end
      end

      # @param other [TimeLength, Numeric]
      # @return [TimeLength]
      def -(other)
        if other.is_a? Item::TimeLength
          self.class.new(value - other.value, pages_per_hour:)
        elsif other.is_a? Numeric
          self.class.new(
            value - self.class.pages_to_minutes(other, pages_per_hour:),
            pages_per_hour:,
          )
        else
          raise TypeError, "#{other.class} can't be subtracted from Item::TimeLength."
        end
      end

      # @param other [TimeLength, Numeric]
      # @return [TimeLength]
      def *(other)
        if other.is_a? Numeric
          self.class.new(value * other, pages_per_hour:).to_i_if_whole!
        else
          raise TypeError, "TimeLength can't be multiplied by #{other.class}."
        end
      end

      # @param other [TimeLength, Numeric]
      # @return [TimeLength]
      def /(other)
        if other.is_a? Numeric
          self.class.new(value / other, pages_per_hour:).to_i_if_whole!
        else
          raise TypeError, "TimeLength can't be divided by #{other.class}."
        end
      end

      # See https://web.archive.org/web/20221206095821/https://www.mutuallyhuman.com/blog/class-coercion-in-ruby/
      # @param other [Numeric]
      def coerce(other)
        if other.is_a? Numeric
          [self.class.from_pages(other, pages_per_hour:), self]
        else
          raise TypeError, "#{other.class} can't be coerced into a TimeLength."
        end
      end

      # @param other [TimeLength, Numeric]
      def <=>(other)
        return 1 if other.nil?

        if other.is_a? Numeric
          other = self.class.from_pages(other, pages_per_hour:)
        end

        unless other.is_a? Item::TimeLength
          raise TypeError, "TimeLength can't be compared to #{other.class} #{other}."
        end

        value <=> other.value
      end
    end
  end
end
