module Reading
  module Parsing
    module Attributes
      # Shared
      module Shared
        # Extracts the :progress sub-attribute (percent, pages, or time) from
        # the given hash.
        # @param hash [Hash] any parsed hash that contains progress.
        # @return [Float, Integer, Item::TimeLength]
        def self.progress(hash)
          hash[:progress_percent]&.to_f&./(100) ||
            hash[:progress_pages]&.to_i ||
            hash[:progress_time]&.then { Item::TimeLength.parse _1 } ||
            (0 if hash[:progress_dnf]) ||
            (1.0 if hash[:progress_done]) ||
            nil
        end

        # Extracts the :length sub-attribute (pages or time) from the given hash.
        # @param hash [Hash] any parsed hash that contains length.
        # @param key_name [Symbol] the first part of the keys to be checked.
        # @param episodic [Boolean] whether to look for episodic (not total) length.
        #   If false, returns nil if hash contains :each. If true, returns a
        #   length only if hash contains :each or if it has repetitions, in
        #   which case repetitions are ignored. Examples of episodic lengths
        #   (before parsing) are "0:30 each" and "1:00 x14" (where the episodic
        #   length is 1:00). Examples of non-episodic lengths are "0:30" and "14:00".
        # @param ignore_repetitions [Boolean] if true, ignores repetitions so
        #   that e.g. "1:00 x14" gives a length of 1 hour instead of 14 hours.
        #   This is useful for the History column, where that 1 hour can be used
        #   as the default amount.
        # @return [Float, Integer, Item::TimeLength]
        def self.length(hash, key_name: :length, episodic: false, ignore_repetitions: false)
          return nil unless hash

          length = hash[:"#{key_name}_pages"]&.to_i ||
            hash[:"#{key_name}_time"]&.then { Item::TimeLength.parse _1 }

          return nil unless length

          if hash[:each]
            # Length is calculated based on History column in this case.
            if episodic
              return length
            else
              return nil
            end
          end

          if hash[:repetitions]
            return length if episodic
            length *= hash[:repetitions].to_i unless ignore_repetitions
          else
            return nil if episodic && !hash[:each]
          end

          length
        end
      end
    end
  end
end
