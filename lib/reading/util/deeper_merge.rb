module Reading
  module Util
    # Modified from active_support/core_ext/hash/deep_merge
    module DeeperMerge
      refine Hash do
        def deeper_merge(other_hash, &block)
          dup.deeper_merge!(other_hash, &block)
        end

        def deeper_merge!(other_hash, &block)
          merge!(other_hash) do |key, this_val, other_val|
            if this_val.is_a?(Hash) && other_val.is_a?(Hash)
              this_val.deeper_merge(other_val, &block)
            # I added this part for merging values that are arrays of hashes.
            elsif this_val.is_a?(Array) && other_val.is_a?(Array) &&
                  this_val.all? { |el| el.is_a?(Hash) } &&
                  other_val.all? { |el| el.is_a?(Hash) }
              zip =
                if other_val.length >= this_val.length
                  other_val.zip(this_val)
                else
                  this_val.zip(other_val).map(&:reverse)
                end
              zip.map do |other_el, this_el|
                if this_el.nil?
                  other_el
                else
                  this_el.deeper_merge(other_el || {})
                end
              end
            elsif block_given?
              block.call(key, this_val, other_val)
            else
              other_val
            end
          end
        end
      end
    end

    # DEPRECATED because it causes Rails to hang. Using ActiveSupport instead.
    # # From active_support/core_ext/object/blank
    # module Blank
    #   refine Object do
    #     def blank?
    #       respond_to?(:empty?) ? !!empty? : !self
    #     end

    #     def present?
    #       !blank?
    #     end

    #     def presence
    #       self if present?
    #     end
    #   end
    # end

    # DEPRECATED because it leads to obscure code.
    # # HashToAttr allows a hash to be made into private attributes of an object.
    # module HashToAttr
    #   refine Hash do
    #     def to_attr_private(obj)
    #       each do |k, v|
    #         obj.instance_variable_set("@#{k}", v.dup)
    #         unless (obj.methods + obj.private_methods).include?(k)
    #           obj.singleton_class.attr_private(k)
    #         end
    #       end
    #     end
    #   end
    # end

    # DEPRECATED because no longer necessary.
    # # MapExtractFirst provides an operation in which:
    # # 1. an array is mapped according to the given block.
    # # 2. the first non-nil element is picked from the mapped array.
    # # 3. its counterpart in (a copy of) the original array is deleted.
    # # 4. the picked element (#2), the smaller array (#3), and the index of the
    # #    picked element are returned.
    # module MapExtractFirst
    #   refine Array do
    #     def map_extract_first(&block)
    #       # return to_enum(:map_extract_first) unless block_given? # error
    #       mapped = map(&block)
    #       match = mapped.compact.first
    #       match_index = mapped.index(match)
    #       without_match = dup.tap do |self_dup|
    #         self_dup.delete_at(mapped.index(match) || self_dup.length) \
    #                                                             unless match.nil?
    #       end
    #       [match, without_match, match_index]
    #     end
    #   end
    # end
  end
end
