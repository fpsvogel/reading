module Reading
  module Util
    # Converts a Hash to a Data. Converts inner hashes (and inner arrays of hashes) as well.
    module HashToData
      refine Hash do
        # @return [Data]
        def to_data
          MEMOIZED_DATAS[keys] ||= Data.define(*keys)
          data_class = MEMOIZED_DATAS[keys]

          data_values = transform_values { |v|
            if v.is_a?(Hash)
              v.to_data
            elsif v.is_a?(Array) && v.all? { |el| el.is_a?(Hash) }
              v.map(&:to_data)#.freeze #TODO
            else
              v.freeze
            end
          }.values

          data_class.new(*data_values)
        end
      end

      private

      MEMOIZED_DATAS = {}
    end
  end
end
