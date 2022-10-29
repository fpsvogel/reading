module Reading
  module Util
    # Modified from active_support/core_ext/hash/deep_merge
    # https://github.com/rails/rails/blob/main/activesupport/lib/active_support/core_ext/hash/deep_merge.rb
    #
    # This deep_merge also iterates through arrays of hashes and merges them.
    module DeepMerge
      refine Hash do
        def deep_merge(other_hash, &block)
          dup.deep_merge!(other_hash, &block)
        end

        def deep_merge!(other_hash, &block)
          merge!(other_hash) do |key, this_val, other_val|
            if this_val.is_a?(Hash) && other_val.is_a?(Hash)
              this_val.deep_merge(other_val, &block)
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
              zip.map { |other_el, this_el|
                if this_el.nil?
                  other_el
                else
                  this_el.deep_merge(other_el || {})
                end
              }
            elsif block_given?
              block.call(key, this_val, other_val)
            else
              other_val
            end
          end
        end
      end
    end
  end
end
