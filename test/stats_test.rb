$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require_relative 'test_helpers/test_helper'

require 'reading'
require 'reading/stats/terminal_result_formatters'
require 'pastel'

class StatsTest < Minitest::Test
  self.class.attr_reader :queries, :config

  PASTEL = Pastel.new

  def config = self.class.config

  @config = Reading.default_config

  # ==== QUERIES FOR TESTS

  @queries = {}

  ## QUERIES: OPERATIONS
  # Simple queries testing each operation, without filters or group-by.
  @queries[:operations] = {
    :"average rating" => {
      input: "average rating",
      result: 3.49499995,
      items: [
        { rating: 3 },
        { rating: 3.9899999 },
        { rating: nil },
      ],
    },
    :"average rating (empty)" => {
      input: "average rating",
      result: nil,
      items: [
        { rating: nil },
      ],
    },
    :"average length" => {
      input: "average length",
      result: 250.5,
      items: [
        { variants: [{ length: 201 }] },
        { variants: [{ length: 300 }] },
        { variants: [{ length: nil }] },
      ],
    },
    :"average length (empty)" => {
      input: "average length",
      result: nil,
      items: [
        { variants: [] },
      ],
    },
    :"average length with pages and time lengths" => {
      input: "average length",
      # assuming 35 pages per hour (the config default)
      result: Reading.time('4:30'),
      items: [
        { variants: [{ length: 175 }] }, # or 5 hours
        { variants: [{ length: Reading.time('4:00') }] },
        { variants: [{ length: nil }] },
      ],
    },
    :"average length with time and pages lengths" => {
      input: "average length",
      # assuming 35 pages per hour (the config default)
      result: Reading.time('4:30'),
      items: [
        { variants: [{ length: Reading.time('5:00') }] },
        { variants: [{ length: 140 }] }, # or 4 hours
        { variants: [{ length: nil }] },
      ],
    },
    :"average item-amount" => {
      input: "average item-amount",
      # assuming 35 pages per hour (the config default)
      result: Reading.time('1:00'),
      items: [
        { experiences: [{ spans: [{ amount: 17.5 }] },
                        { spans: [{ amount: 17.5 }, { amount: Reading.time('1:00') }] }] },
        { experiences: [{ spans: [{ amount: 35 }] }] },
        { experiences: [] },
      ],
    },
    :"average item-amount (empty)" => {
      input: "average item-amount",
      result: 0,
      items: [
        { experiences: [] },
      ],
    },
    :"average daily-amount" => {
      input: "average daily-amount",
      # assuming 35 pages per hour (the config default)
      result: Reading.time('1:00'),
      items: [
        { experiences:
          [{ spans: [{ dates: Date.new(2023, 5, 1)..Date.new(2023, 5, 2), amount: Reading.time('1:00') }] },
            { spans: [{ dates: Date.new(2023, 5, 5)..Date.new(2023, 5, 5), amount: 35 },
                      { dates: Date.new(2023, 5, 10)..Date.new(2023, 5, 11), amount: 70 }] }] },
        # 2022/9/30 because Date::today is stubbed to 2022/10/1 in test_helper.rb
        { experiences: [{ spans: [{ dates: Date.new(2022, 9, 30).., amount: 105 }] }] },
        { experiences: [] },
      ],
    },
    :"average daily-amount (empty)" => {
      input: "average daily-amount",
      result: nil,
      items: [
        { experiences: [] },
      ],
    },
    :"total items" => {
      input: "total item",
      result: 2,
      items: [
        {},
        {},
      ],
    },
    :"total amount" => {
      input: "total amount",
      # assuming 35 pages per hour (the config default)
      result: Reading.time('3:00'),
      items: [
        { experiences: [{ spans: [{ amount: 17.5 }] },
                        { spans: [{ amount: 17.5 }, { amount: Reading.time('1:00') }] }] },
        { experiences: [{ spans: [{ amount: 35 }] }] },
        { experiences: [] },
      ],
    },
    :"top ratings" => {
      input: "top 2 rating",
      result: [["Whoa.", 5], ["Mehhh", 3]],
      items: [
        { title: "Trash", rating: 2 },
        { title: "Whoa.", rating: 5 },
        { title: "Mehhh", rating: 3 },
      ],
    },
    :"top ratings without number arg" => {
      input: "top rating",
      result: Reading::Stats::Operation.const_get(:DEFAULT_NUMBER_ARG).times.map { ["Better", 3] },
      items: [
        { title: "Trash", rating: 2 },
        *10.times.map { { title: "Better", rating: 3 } },
      ],
    },
    :"top lengths" => {
      input: "top 2 length",
      result: [["Encyclopedic", 1000], ["Longish", Reading.time('10:00')]],
      items: [
        { title: "Short", variants: [{ length: 100 }] },
        { title: "Encyclopedic", variants: [{ length: 1000 }] },
        { title: "Longish", variants: [{ length: Reading.time('10:00') }] },
        { title: "No length", variants: [{ length: nil }] },
      ],
    },
    :"top speeds" => {
      input: "top 2 speed",
      result: [["Sprint", { amount: 200, days: 1 }], ["Jog", { amount: Reading.time('5:00'), days: 5 }]],
      items: [
        { title: "Walk", experiences: [{ spans: [
          { dates: Date.new(2023,5,1)..Date.new(2023,5,3), amount: 200 },
          { dates: Date.new(2023,5,5)..Date.new(2023,5,15), amount: 200 },
        ] }] },
        { title: "Sprint", experiences: [{ spans: [
          { dates: Date.new(2023,5,1)..Date.new(2023,5,1), amount: 200 },
        ] }] },
        { title: "Jog", experiences: [{ spans: [
          { dates: Date.new(2023,5,1)..Date.new(2023,5,5), amount: Reading.time('5:00') },
        ] }] },
        { title: "DNF", experiences: [{ spans: [
          { dates: Date.new(2023,5,1)..Date.new(2023,5,1), amount: 300, progress: 0.10 },
        ] }] },
        { title: "Planned", experiences: [{ spans: [
          { dates: nil, amount: 1000 },
        ] }] },
        { title: "Endless range", experiences: [{ spans: [
          { dates: Date.new(2023,5,1).., amount: 1000 },
        ] }] },
      ],
    },
    :"bottom ratings" => {
      input: "bottom 2 rating",
      result: [["Trash", 2], ["Mehhh", 3]],
      items: [
        { title: "Trash", rating: 2 },
        { title: "Whoa.", rating: 5 },
        { title: "Mehhh", rating: 3 },
      ],
    },
    :"bottom lengths" => {
      input: "bottom 2 length",
      result: [["Short", 100], ["Longish", Reading.time('10:00')]],
      items: [
        { title: "Short", variants: [{ length: 100 }] },
        { title: "Encyclopedic", variants: [{ length: 1000 }] },
        { title: "Longish", variants: [{ length: Reading.time('10:00') }] },
        { title: "No length", variants: [{ length: nil }] },
      ],
    },
    :"bottom speeds" => {
      input: "bottom 2 speed",
      result: [["Walk", { amount: 400, days: 14 }], ["DNF", { amount: 30, days: 1 }]],
      items: [
        { title: "Walk", experiences: [{ spans: [
          { dates: Date.new(2023,5,1)..Date.new(2023,5,3), amount: 200 },
          { dates: Date.new(2023,5,5)..Date.new(2023,5,15), amount: 200 },
        ] }] },
        { title: "Sprint", experiences: [{ spans: [
          { dates: Date.new(2023,5,1)..Date.new(2023,5,1), amount: 200 },
        ] }] },
        { title: "Jog", experiences: [{ spans: [
          { dates: Date.new(2023,5,1)..Date.new(2023,5,5), amount: Reading.time('5:00') },
        ] }] },
        { title: "DNF", experiences: [{ spans: [
          { dates: Date.new(2023,5,1)..Date.new(2023,5,1), amount: 300, progress: 0.10 },
        ] }] },
        { title: "Planned", experiences: [{ spans: [
          { dates: nil, amount: 100 },
        ] }] },
        { title: "Endless range", experiences: [{ spans: [
          { dates: Date.new(2023,5,1).., amount: 100 },
        ] }] },
      ],
    },
  }



  ## QUERIES: FILTERS
  # Simple queries testing each filter.
  @queries[:filters] = {
    :"genre" => {
      input: "average rating genre=history",
      result: 4,
      items: [
        { rating: 3, genres: ["fiction"] },
        { rating: 4, genres: ["history"] },
      ],
    },
    :"genre (not)" => {
      input: "average rating genre!=history",
      result: 3,
      items: [
        { rating: 3, genres: ["fiction"] },
        { rating: 4, genres: ["history"] },
      ],
    },
    :"genre (or)" => {
      input: "average rating genre=history,fiction",
      result: 3.5,
      items: [
        { rating: 3, genres: ["fiction"] },
        { rating: 4, genres: ["history"] },
      ],
    },
    :"genre (and)" => {
      input: "average rating genre=history+fiction",
      result: 3,
      items: [
        { rating: 3, genres: ["fiction", "history"] },
        { rating: 4, genres: ["history"] },
      ],
    },
    :"genre (alt. and)" => {
      input: "average rating genre=history genre=fiction",
      result: 3,
      items: [
        { rating: 3, genres: ["fiction", "history"] },
        { rating: 4, genres: ["history"] },
      ],
    },
    :"genre (or, and)" => {
      input: "average rating genre=science,history+fiction",
      result: 2.5,
      items: [
        { rating: 3, genres: ["fiction", "history"] },
        { rating: 4, genres: ["history"] },
        { rating: 2, genres: ["science"] },
      ],
    },
    :"rating" => {
      input: "average rating rating=3",
      result: 3,
      items: [
        { rating: 3 },
        { rating: 4 },
      ],
    },
    :"rating (not)" => {
      input: "average rating rating!=3",
      result: 4,
      items: [
        { rating: 3 },
        { rating: 4 },
      ],
    },
    :"rating (multiple)" => {
      input: "average rating rating=3,4",
      result: 3.5,
      items: [
        { rating: 3 },
        { rating: 4 },
        { rating: 5 },
      ],
    },
    :"rating (greater than)" => {
      input: "average rating rating>4",
      result: 5,
      items: [
        { title: "yoyo", rating: 3 },
        { rating: 4 },
        { rating: 5 },
      ],
    },
    :"rating (greater than or equal to)" => {
      input: "average rating rating>=4",
      result: 4.5,
      items: [
        { rating: 3 },
        { rating: 4 },
        { rating: 5 },
      ],
    },
    :"rating (less than)" => {
      input: "average rating rating<5",
      result: 3.5,
      items: [
        { rating: 3 },
        { rating: 4 },
        { rating: 5 },
      ],
    },
    :"rating (less than or equal to)" => {
      input: "average rating rating<=4",
      result: 3.5,
      items: [
        { rating: 3 },
        { rating: 4 },
        { rating: 5 },
      ],
    },
    :"rating (greater than 1, less than 5)" => {
      input: "average rating rating>1 rating<5",
      result: 4,
      items: [
        { rating: 1 },
        { rating: 4 },
        { rating: 5 },
      ],
    },
    :"format" => {
      input: "average rating format=print",
      result: 3,
      items: [
        { rating: 3, variants: [{ format: :print }] },
        { rating: 4, variants: [{ format: :audio }] },
        { rating: 5, variants: [] },
      ],
    },
    :"format (not)" => {
      input: "average rating format!=print",
      result: 4.5,
      items: [
        { rating: 3, variants: [{ format: :print }] },
        { rating: 4, variants: [{ format: :audio }] },
        { rating: 5, variants: [] },
      ],
    },
    :"format (multiple)" => {
      input: "average rating format=print,audio",
      result: 3.5,
      items: [
        { rating: 3, variants: [{ format: :print }, { format: :audio }] },
        { rating: 4, variants: [{ format: :audio }] },
        { rating: 5, variants: [] },
      ],
    },
    :"format filters out non-matching variants" => {
      input: "average length format=print",
      result: 10,
      items: [
        { variants: [{ format: :print, length: 10 }, { format: :audio, length: 20}] },
      ],
    },
    :"format filters out non-matching experiences" => {
      input: "average item-amount format=print",
      result: 10,
      items: [
        { variants: [{ format: :audio }, { format: :print }],
          experiences: [{ variant_index: 0, spans: [{ amount: 20 }] }, { variant_index: 1, spans: [{ amount: 10 }] }] },
      ],
    },
    :"source" => {
      input: "average rating source=little library",
      result: 3,
      items: [
        { rating: 3, variants: [{ sources: [{ name: "Little Library", url: nil }] }] },
        { rating: 4, variants: [{ sources: [{ name: nil, url: "https://archive.org"}] }] },
        { rating: 5, variants: [] },
      ],
    },
    :"source (not)" => {
      input: "average rating source!=little library",
      result: 4.5,
      items: [
        { rating: 3, variants: [{ sources: [{ name: "Little Library", url: nil }] }] },
        { rating: 4, variants: [{ sources: [{ name: nil, url: "https://archive.org"}] }] },
        { rating: 5, variants: [] },
      ],
    },
    :"source (multiple)" => {
      input: "average rating source=little library,https://archive.org",
      result: 3.5,
      items: [
        { rating: 3, variants: [{ sources: [{ name: "Little Library", url: nil }, { name: nil, url: "https://archive.org"}] }] },
        { rating: 4, variants: [{ sources: [{ name: nil, url: "https://archive.org"}] }] },
        { rating: 5, variants: [] },
      ],
    },
    :"source (includes)" => {
      input: "average rating source~library,archive",
      result: 3.5,
      items: [
        { rating: 3, variants: [{ sources: [{ name: "Little Library", url: nil }, { name: nil, url: "https://archive.org"}] }] },
        { rating: 4, variants: [{ sources: [{ name: nil, url: "https://archive.org"}] }] },
        { rating: 5, variants: [] },
      ],
    },
    :"source (excludes)" => {
      input: "average rating source!~library,archive",
      result: 5,
      items: [
        { rating: 3, variants: [{ sources: [{ name: "Little Library", url: nil }, { name: nil, url: "https://archive.org"}] }] },
        { rating: 4, variants: [{ sources: [{ name: nil, url: "https://archive.org"}] }] },
        { rating: 5, variants: [] },
      ],
    },
  }



  ## QUERIES: RESULT FORMATTERS
  # Minimal queries testing result formatters.
  @queries[:terminal_result_formatters] = {
    :"average length (pages)" => {
      input: "average length",
      result: PASTEL.bright_blue("200 pages"),
      items: [
        { variants: [{ length: 200 }], experiences: [{ variant_index: 0 }] },
      ],
    },
    :"average length (time)" => {
      input: "average length",
      # assuming 35 pages per hour (the config default)
      result: PASTEL.bright_blue("5:00 or 175 pages"),
      items: [
        { variants: [{ length: Reading.time('5:00') }], experiences: [{ variant_index: 0 }] },
      ],
    },
    :"average length (time, with custom pages per hour)" => {
      input: "average length",
      result: PASTEL.bright_blue("5:00 or 500 pages"),
      items: [
        { variants: [{ length: Reading.time('5:00', pages_per_hour: 100) }],
                        experiences: [{ variant_index: 0 }] },
      ],
      config: { pages_per_hour: 100 },
    },
    :"total items (singular)" => {
      input: "total item",
      result: PASTEL.bright_blue("1 item"),
      items: [
        {},
      ],
    },
    :"total items (plural)" => {
      input: "total item",
      result: PASTEL.bright_blue("2 items"),
      items: [
        {},
        {},
      ],
    },
    :"total amount" => {
      input: "total amount",
      result: PASTEL.bright_blue("2 pages"),
      items: [
        { experiences: [{ spans: [{ amount: 2 }] }] },
      ],
    },
    :"total amount (zero)" => {
      input: "total amount",
      result: PASTEL.bright_blue("0 pages"),
      items: [
        { experiences: [] },
      ],
    },
    :"total amount (time, with custom pages per hour)" => {
      input: "total amount",
      result: PASTEL.bright_blue("5:00 or 500 pages"),
      items: [
        { experiences: [{ spans: [{ amount: Reading.time('5:00', pages_per_hour: 100) }] }] },
      ],
      config: { pages_per_hour: 100 },
    },
    :"top lengths" => {
      input: "top 2 length",
      result: "1. Encyclopedic\n     #{PASTEL.bright_blue("1000 pages")}\n" \
        "2. Short\n     #{PASTEL.bright_blue("100 pages")}",
      items: [
        { title: "Short", variants: [{ length: 100 }] },
        { title: "Encyclopedic", variants: [{ length: 1000 }] },
      ],
    },
    :"top speeds" => {
      input: "top 2 speed",
      # assuming 35 pages per hour (the config default)
      result: "1. Sprint\n     #{PASTEL.bright_blue("200 pages in 1 day")}\n" \
        "2. Jog\n     #{PASTEL.bright_blue("6:00 or 210 pages in 5 days")}",
      items: [
        { title: "Sprint", experiences: [{ spans: [
          { dates: Date.new(2023,5,1)..Date.new(2023,5,1), amount: 200 },
        ] }] },
        { title: "Jog", experiences: [{ spans: [
          { dates: Date.new(2023,5,1)..Date.new(2023,5,5), amount: Reading.time('6:00') },
        ] }] },
      ],
    },
    :"bottom lengths" => {
      input: "bottom 2 length",
      # assuming 35 pages per hour (the config default)
      result: "1. Short\n     #{PASTEL.bright_blue("100 pages")}\n" \
        "2. Longish\n     #{PASTEL.bright_blue("10:00 or 350 pages")}",
      items: [
        { title: "Short", variants: [{ length: 100 }] },
        { title: "Longish", variants: [{ length: Reading.time('10:00') }] },
      ],
    },
    :"bottom speeds" => {
      input: "bottom 2 speed",
      result: "1. Walk\n     #{PASTEL.bright_blue("400 pages in 14 days")}\n" \
        "2. DNF\n     #{PASTEL.bright_blue("30 pages in 1 day")}",
      items: [
        { title: "Walk", experiences: [{ spans: [
          { dates: Date.new(2023,5,1)..Date.new(2023,5,3), amount: 200 },
          { dates: Date.new(2023,5,5)..Date.new(2023,5,15), amount: 200 },
        ] }] },
        { title: "DNF", experiences: [{ spans: [
          { dates: Date.new(2023,5,1)..Date.new(2023,5,1), amount: 300, progress: 0.10 },
        ] }] },
      ],
    },
  }

  # ==== TESTS

  # TESTS: OPERATIONS
  queries[:operations].each do |key, hash|
    define_method("test_operation_#{key}") do
      items = hash.fetch(:items).map { |item_hash|
        Reading::Item.new(
          item_hash,
          config:,
          view: false,
        )
      }

      input = hash.fetch(:input)

      exp = hash.fetch(:result)
      act = Reading.stats(input:, items:)
      # debugger unless exp == act

      if exp.nil?
        assert_nil act, "Unexpected result #{act} from stats query \"#{name}\""
      else
        assert_equal exp, act,
          "Unexpected result #{act} from stats query \"#{name}\""
      end

      # Alternate input styles
      # a. Plural second word
      act = Reading.stats(input: "#{input}s", items:)
      exp.nil? ? assert_nil(act) : assert_equal(exp, act)

      # b. Aliases
      op_key = input.split(/\s*\d+\s*|\s+/).join('_').to_sym
      number_arg = Integer(input[/\d+/], exception: false)
      op_aliases = Reading::Stats::Operation.const_get(:ALIASES).fetch(op_key)

      op_aliases.each do |op_alias|
        act = Reading.stats(input: "#{op_alias}#{" " + number_arg.to_s if number_arg}", items:)
        exp.nil? ? assert_nil(act) : assert_equal(exp, act)
      end

      # c. Plural aliases
      op_aliases.each do |op_alias|
        act = Reading.stats(input: "#{op_alias}s#{" " + number_arg.to_s if number_arg}", items:)
        exp.nil? ? assert_nil(act) : assert_equal(exp, act)
      end
    end
  end

  # TESTS: FILTERS
  queries[:filters].each do |key, hash|
    define_method("test_filter_#{key}") do
      items = hash.fetch(:items).map { |item_hash|
        Reading::Item.new(
          item_hash,
          config:,
          view: false,
        )
      }

      input = hash.fetch(:input)

      exp = hash.fetch(:result)
      act = Reading.stats(input:, items:)
      # debugger unless exp == act

      assert_equal exp, act,
        "Unexpected result #{act} from stats query \"#{name}\""

      # Alternate input styles:
      # a. Plural
      plural_input = input.gsub(/(\w\s*)(!=|=|!~|~|>=|>|<=|<)/, '\1s\2')
      act = Reading.stats(input: plural_input, items:)
      assert_equal exp, act

      # b. With spaces
      spaced = input
        .gsub(/(!=|=|!~|~|>=|>|<=|<)/, ' \1 ')
        .gsub(',', ', ')
        .gsub('+', ' + ')
    end
  end

  # TESTS: RESULT FORMATTERS
  queries[:terminal_result_formatters].each do |key, hash|
    define_method("test_result_formatter_#{key}") do
      items = hash.fetch(:items).map { |item_hash|
        custom_config = Reading::Config.hash(hash[:config]) if hash[:config]

        Reading::Item.new(
          item_hash,
          config: custom_config || config,
          view: false,
        )
      }

      exp = hash.fetch(:result)
      act = Reading.stats(
        input: hash.fetch(:input),
        items:,
        result_formatters: Reading::Stats::ResultFormatters::TERMINAL,
      )
      # debugger unless exp == act
      assert_equal exp, act,
        "Unexpected result #{act} from stats query \"#{name}\""
    end
  end
end
