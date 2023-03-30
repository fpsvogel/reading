module Reading
  module Item
    # For coercion, see https://www.mutuallyhuman.com/blog/class-coercion-in-ruby/
    class TimeLength
      include Comparable

      attr_reader :value # in total minutes

      # @param value [Numeric] the total minutes
      def initialize(value)
        @value = value
      end

      # Builds a TimeLength from a string.
      # @param string [String] a time duration in "h:mm" format.
      # @return [TimeLength]
      def self.parse(string)
        hours, minutes = string.split(':').map(&:to_i)
        new((hours * 60) + minutes)
      end

      # Only the hours, e.g. the "h" value in "h:mm".
      # @return [Numeric]
      def hours
        value / 60
      end

      # Only the hours, e.g. the "mm" value in "h:mm".
      # @return [Numeric]
      def minutes
        value % 60
      end

      # A string in "h:mm" format.
      # @return [String]
      def to_s
        "#{hours}:#{minutes}"
      end

      # @return [Boolean]
      def zero?
        value.zero?
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

      # TODO: addition with pages (nonzero Integer)
      # @param other [TimeLength, Integer] must be zero if it's an Integer.
      # @return [TimeLength]
      def +(other)
        if other.is_a? TimeLength
          self.class.new(value + other.value)
        elsif other.zero?
          self
        else
          raise TypeError, "#{other.class} can't be added to TimeLength."
        end
      end

      # TODO: subtraction with pages (nonzero Integer)
      # @param other [TimeLength, Integer] must be zero if it's an Integer.
      # @return [TimeLength]
      def -(other)
        if other.is_a? TimeLength
          self.class.new(value - other.value)
        elsif other.zero?
          self
        else
          raise TypeError, "#{other.class} can't be subtracted from TimeLength."
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

      # TODO: add coercion for pages (nonzero Integer)
      # @param other [Integer] must be zero.
      def coerce(other)
        if other.zero?
          [self.class.new(other), self]
        else
          raise TypeError, "TimeLength can't be coerced into #{other.class}."
        end
      end

      # TODO: add comparison to pages (nonzero Integer)
      # @param other [TimeLength, Integer] if Integer, must be zero.
      def <=>(other)
        return 1 if other.nil?

        if other.zero?
          return 0 if value.zero?
          return 1
        end

        unless other.is_a? TimeLength
          raise TypeError, "TimeLength can't be compared to #{other.class} #{other}."
        end

        value <=> other.value
      end
    end
  end
end
