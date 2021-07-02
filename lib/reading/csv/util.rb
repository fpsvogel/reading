# frozen_string_literal: true

require "attr_extras"
require "pastel"
require "date"

# from active_support/core_ext/object/blank
module Blank
  refine Object do
    def blank?
      respond_to?(:empty?) ? !!empty? : !self
    end

    def present?
      !blank?
    end

    def presence
      self if present?
    end
  end
end

module Reading
  Colors = Pastel.new

  # HashToAttr allows a hash to be made into private attributes of an object.
  module HashToAttr
    refine Hash do
      def to_attr_private(obj)
        each do |k, v|
          obj.instance_variable_set("@#{k}", v.dup)
          unless (obj.methods + obj.private_methods).include?(k)
            obj.singleton_class.attr_private(k)
          end
        end
      end
    end
  end

  # MapExtractFirst provides an operation in which:
  # 1. an array is mapped according to the given block.
  # 2. the first non-nil element is picked from the mapped array.
  # 3. its counterpart in (a copy of) the original array is deleted.
  # 4. the picked element (#2), the smaller array (#3), and the index of the
  #    picked element are returned.
  module MapExtractFirst
    refine Array do
      def map_extract_first(&block)
        # return to_enum(:map_extract_first) unless block_given? # error
        mapped = map(&block)
        match = mapped.compact.first
        match_index = mapped.index(match)
        without_match = dup.tap do |self_dup|
          self_dup.delete_at(mapped.index(match) || self_dup.length) \
                                                              unless match.nil?
        end
        [match, without_match, match_index]
      end
    end
  end
end

