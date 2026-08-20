module Reading
  module Parsing
    module Attributes
      # Transformer for the :notes item attribute.
      class Notes < Attribute
        # @param parsed_row [Hash] a parsed row (the intermediate hash).
        # @param _head_index [Integer] current item's position in the Head column.
        # @return [Array<Hash>] an array of notes; see
        #   Config#default_config[:item][:template][:notes]
        def transform_from_parsed(parsed_row, _head_index)
          parsed_row[:notes]&.map { |note|
            {
              blurb?: note.has_key?(:blurb),
              private?: note.has_key?(:private),
              date: date(note[:date]),
              rating_change: rating_change(note[:rating_from], note[:rating_to]),
              content: note[:content],
            }
          }.then { distribute_dates_to_rating_changes!(it, parsed_row) }
          .then { capitalize_content_of_rating_changes!(it, parsed_row) }
        end

        private

        def date(date_string)
          return nil unless date_string

          Date.parse(date_string)
        rescue Date::Error
          raise InvalidDateError, "Unparsable date \"#{date_string}\""
        end

        def rating_change(rating_from, rating_to)
          return [] unless rating_from && rating_to

          [Integer(rating_from), Integer(rating_to)]
        end

        # Rating change notes without dates are automatically given the end or
        # start dates of the item's experiences in reverse order.
        def distribute_dates_to_rating_changes!(transformed_notes, parsed_row)
          return unless transformed_notes
          experiences = Experiences.new.transform_from_parsed(parsed_row, 0)

          transformed_notes.reverse_each do |note|
            return if experiences.empty?
            next if note[:rating_change].empty? || note[:date]
            last_experience = experiences.pop
            note[:date] = last_experience[:spans].last[:dates]&.end || last_experience[:spans].first[:dates]&.begin
          end
        end

        def capitalize_content_of_rating_changes!(transformed_notes, parsed_row)
          return unless transformed_notes

          transformed_notes.each do |note|
            next if note[:rating_change].empty? || note[:content].nil?
            note[:content].capitalize!
          end
        end
      end
    end
  end
end
