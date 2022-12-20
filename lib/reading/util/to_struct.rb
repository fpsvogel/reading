module Reading
  module Util
    # Converts a Hash to a Struct.
    module ToStruct
      refine Hash do
        MEMOIZED_STRUCTS = {}

        def to_struct
          MEMOIZED_STRUCTS[keys] ||= Struct.new(*keys)
          struct_class = MEMOIZED_STRUCTS[keys]

          struct_values = transform_values { |v|
            if v.is_a?(Hash)
              v.to_struct
            elsif v.is_a?(Array) && v.all? { |el| el.is_a?(Hash) }
              v.map(&:to_struct)
            else
              v
            end
          }.values

          struct_class.new(*struct_values)
        end
      end
    end
  end
end
