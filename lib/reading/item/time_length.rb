module Reading
  class Item
    # The length of an item when it is a time, as opposed to pages. (Pages are
    # represented simply with an Integer or Float.)
    class Item::TimeLength
      include Comparable

      attr_reader :value # in total minutes

      # @param value [Numeric] the total minutes
      def initialize(value)
        @value = value
      end

      # Builds an Item::TimeLength from a string.
      # @param string [String] a time duration in "h:mm" format.
      # @return [TimeLength, nil]
      def self.parse(string)
        return nil unless string.match? /\A\d+:\d\d\z/

        hours, minutes = string.split(':').map(&:to_i)
        new((hours * 60) + minutes)
      end

      # Builds an Item::TimeLength based on a page count.
      # @param pages [Integer, Float]
      # @return [TimeLength]
      def self.from_pages(pages)
        new(pages_to_minutes(pages))
      end

      # Converts a page count to minutes.
      # @param pages [Integer, Float]
      # @return [Integer]
      def self.pages_to_minutes(pages)
        (pages.to_f / Config.hash.fetch(:pages_per_hour) * 60)
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
        "#{hours}:#{minutes.round.to_s.rjust(2, '0')} or #{(value / 60.0 * Config.hash.fetch(:pages_per_hour)).round} pages"
      end

      # To pages.
      # @return [Integer]
      def to_i
        ((value / 60.0) * Config.hash.fetch(:pages_per_hour)).to_i
      end

      # @return [Boolean]
      def zero?
        value.zero?
      end

      # A copy of self with a rounded @value.
      # @return [TimeLength]
      def round
        self.class.new(@value.round)
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

        self.class.new(@value.to_i)
      end

      # @param other [TimeLength, Numeric]
      # @return [TimeLength]
      def +(other)
        if other.is_a? Item::TimeLength
          self.class.new(value + other.value)
        elsif other.is_a? Numeric
          self.class.new(value + self.class.pages_to_minutes(other))
        else
          raise TypeError, "#{other.class} can't be added to Item::TimeLength."
        end
      end

      # @param other [TimeLength, Numeric]
      # @return [TimeLength]
      def -(other)
        if other.is_a? Item::TimeLength
          self.class.new(value - other.value)
        elsif other.is_a? Numeric
          self.class.new(value - self.class.pages_to_minutes(other))
        else
          raise TypeError, "#{other.class} can't be subtracted from Item::TimeLength."
        end
      end

      # @param other [TimeLength, Numeric]
      # @return [TimeLength]
      def *(other)
        if other.is_a? Numeric
          self.class.new(value * other).to_i_if_whole!
        else
          raise TypeError, "TimeLength can't be multiplied by #{other.class}."
        end
      end

      # @param other [TimeLength, Numeric]
      # @return [TimeLength]
      def /(other)
        if other.is_a? Numeric
          self.class.new(value / other).to_i_if_whole!
        else
          raise TypeError, "TimeLength can't be divided by #{other.class}."
        end
      end

      # See https://web.archive.org/web/20221206095821/https://www.mutuallyhuman.com/blog/class-coercion-in-ruby/
      # @param other [Numeric]
      def coerce(other)
        if other.is_a? Numeric
          [self.class.from_pages(other), self]
        else
          raise TypeError, "#{other.class} can't be coerced into a TimeLength."
        end
      end

      # @param other [TimeLength, Numeric]
      # @return  [Integer]
      def <=>(other)
        return 1 if other.nil?

        if other.is_a? Numeric
          other = self.class.from_pages(other)
        end

        unless other.is_a? Item::TimeLength
          raise TypeError, "TimeLength can't be compared to #{other.class} #{other}."
        end

        value <=> other.value
      end

      # Must be implemented for hash key equality checks.
      # @param other [TimeLength, Numeric]
      # @return [Boolean]
      def eql?(other)
        hash == other.hash
      end

      # Must be implemented along with #eql? for hash key equality checks.
      # @return [Integer]
      def hash
        value
      end
    end
  end
end
