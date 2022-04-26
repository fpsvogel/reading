require "date"

module Reading
  module Csv
    class Parse
      class ParseLine
        class ParseHistory < ParseAttribute

          # GOATSONG example in @files[:examples][:in_progress]
          # [{ dates: Date.parse("2019-05-01"), amount: 31 },
          #   { dates: Date.parse("2019-05-02"), amount: 23 },
          #   { dates: Date.parse("2019-05-06")..Date.parse("2019-05-15"), amount: 10 },
          #   { dates: Date.parse("2019-05-20"), amount: 46 },
          #   { dates: Date.parse("2019-05-21"), amount: 47 }]

          # 5|50% 📕Tom Holt - Goatsong: A Novel of Ancient Athens -- The Walled Orchard, #1|0312038380|2019/05/28, 2020/05/01, 2021/08/17|2019/06/13, 2020/05/23|historical fiction|247||||2019/5/1 p31 -- 5/2 p54 -- 5/6-15 10p -- 5/20 p200 -- 5/21 done

          def call(_name = nil, columns)
            # split_notes(:history, columns)
            [{ dates: nil,
              amount: nil,
              description: nil }]
          end

          def split_notes(column_name, columns)
            return nil unless columns[column_name]
            columns[column_name]
              .presence
              &.chomp
              &.sub(/#{@config.fetch(:csv).fetch(:long_separator).rstrip}\s*\z/, "")
              &.split(@config.fetch(:csv).fetch(:long_separator))
          end
        end
      end
    end
  end
end