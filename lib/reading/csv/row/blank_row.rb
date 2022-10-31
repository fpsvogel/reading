require_relative "row"

module Reading
  class CSV
    # A null object which returns an empty array.
    class BlankRow < Row
      def parse(line)
        []
      end
    end
  end
end
