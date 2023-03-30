module Reading
  module Item
    # For coercion, see https://www.mutuallyhuman.com/blog/class-coercion-in-ruby/
    class TimeLength
      include Comparable

      attr_reader :value # in total minutes

      def initialize(value)
        @value = value
      end

      def self.parse(string)
        hours, minutes = string.split(':').map(&:to_i)
        new((hours * 60) + minutes)
      end

      def hours
        (value / 60).round
      end

      def minutes
        (value % 60).round
      end

      def to_s
        "#{hours}:#{minutes}"
      end

      def +(other)
        if other.is_a? TimeLength
          TimeLength.new(value + other.value)
        else
          raise TypeError, "#{other.class} can't be coerced into TimeLength."
        end
      end

      def *(other)
        if other.is_a?(Integer) || other.is_a?(Float)
          TimeLength.new(value * other)
        else
          raise TypeError, "TimeLength can't be multiplied by #{other.class}."
        end
      end

      def /(other)
        if other.is_a?(Integer) || other.is_a?(Float)
          TimeLength.new(value / other)
        else
          raise TypeError, "TimeLength can't be divided by #{other.class}."
        end
      end

      def <=>(other)
        return 1 if other.nil?

        unless other.is_a? TimeLength
          raise TypeError, "TimeLength can't be compared to #{other.class}."
        end

        value <=> other.value
      end
    end
  end
end
