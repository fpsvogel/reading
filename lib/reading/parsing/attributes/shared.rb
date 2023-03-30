module Reading
  module Parsing
    module Attributes
      module Shared
        # Extracts progress (percent, pages, or time) from the given hash.
        # @param hash [Hash]
        # @return [Float, Integer, Reading::Item::TimeLength]
        def self.progress(hash)
          hash[:progress_percent]&.to_f&./(100) ||
            hash[:progress_pages]&.to_i ||
            hash[:progress_time]&.then { Item::TimeLength.parse _1 } ||
            (0 if hash[:progress_dnf]) ||
            nil
        end

        # Extracts length (pages or time) from the given hash.
        # @param hash [Hash]
        # @param key_name [Symbol] the first part of the keys to be checked.
        # @param nil_if_each [Boolean] if true, returns nil if hash contains :each.
        # @return [Float, Integer, Reading::Item::TimeLength]
        def self.length(hash, key_name: :length, nil_if_each: false)
          return nil unless hash

          # Length is calculated based on History column in this case.
          return nil if hash[:each] && nil_if_each

          length = hash[:"#{key_name}_pages"]&.to_i ||
            hash[:"#{key_name}_time"]&.then { Item::TimeLength.parse _1 }

          return nil unless length

          length *= hash[:repetitions].to_i if hash[:repetitions]

          length
        end
      end
    end
  end
end
