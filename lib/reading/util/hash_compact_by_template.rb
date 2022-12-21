module Reading
  module Util
    # Utility method for a hash containing parsed item data, structured as the
    # template in config.rb.
    module HashCompactByTemplate
      refine Hash do
        # Removes blank arrays of hashes from the given item hash, e.g. series,
        # variants, variants[:sources], and experiences in the template in config.rb.
        # If no parsed data has been added to the template values for these, they
        # are considered blank, and are replaced with an empty array so that their
        # emptiness is more apparent, e.g. item[:experiences].empty? will return true.
        def compact_by(template:)
          map { |key, val|
            if is_array_of_hashes?(val)
              if is_blank_like_template?(val, template.fetch(key))
                [key, []]
              else
                [key, val.map { |el| el.compact_by(template: template.fetch(key).first) }]
              end
            else
              [key, val]
            end
          }.to_h
        end

        private

        def is_array_of_hashes?(val)
          val.is_a?(Array) && val.first.is_a?(Hash)
        end

        def is_blank_like_template?(val, template_val)
          val.length == 1 && val == template_val
        end
      end
    end
  end
end
