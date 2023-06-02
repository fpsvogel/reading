$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "test_helpers/test_helper"

require "reading"

class StatsTest < Minitest::Test
  self.class.attr_reader :queries, :config

  def config = self.class.config

  @config = Reading::Config.new.hash

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
    :"average length" => {
      input: "average length",
      result: 250.5,
      items: [
        { variants: [{ length: 201 }] },
        { variants: [{ length: 300 }] },
        { variants: [{ length: nil }] },
      ],
    },
    :"average length with pages and time lengths" => {
      input: "average length",
      result: Reading.time("4:30"), # assuming 35 pages per hour (the config default)
      items: [
        { variants: [{ length: 175 }] }, # or 5 hours
        { variants: [{ length: Reading.time("4:00") }] },
        { variants: [{ length: nil }] },
      ],
    },
    :"average length with time and pages lengths" => {
      input: "average length",
      result: Reading.time("4:30"), # assuming 35 pages per hour (the config default)
      items: [
        { variants: [{ length: Reading.time("5:00") }] },
        { variants: [{ length: 140 }] }, # or 4 hours
        { variants: [{ length: nil }] },
      ],
    },
    :"average amount" => {
      input: "average amount",
      result: Reading.time("1:00"), # assuming 35 pages per hour (the config default)
      items: [
        { experiences:
          [{ spans: [{ dates: Date.new(2023, 5, 1)..Date.new(2023, 5, 2), amount: Reading.time("1:00") }] },
            { spans: [{ dates: Date.new(2023, 5, 5)..Date.new(2023, 5, 5), amount: 35 },
                      { dates: Date.new(2023, 5, 10)..Date.new(2023, 5, 11), amount: 70 }] }] },
        # 2022/9/30 because Date::today is stubbed to 2022/10/1 in test_helper.rb
        { experiences: [{ spans: [{ dates: Date.new(2022, 9, 30).., amount: 105 }] }] },
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
      result: Reading.time("3:00"), # assuming 35 pages per hour (the config default)
      items: [
        { experiences: [{ spans: [{ amount: 17.5 }] },
                        { spans: [{ amount: 17.5 }, { amount: Reading.time("1:00") }] }] },
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
      result: Reading::Stats::Operation::DEFAULT_NUMBER_ARG.times.map { ["Better", 3] },
      items: [
        { title: "Trash", rating: 2 },
        *10.times.map { { title: "Better", rating: 3 } },
      ],
    },
    :"top lengths" => {
      input: "top 2 length",
      result: [["Encyclopedic", 1000], ["Longish", Reading.time("10:00")]],
      items: [
        { title: "Short", variants: [{ length: 100 }] },
        { title: "Encyclopedic", variants: [{ length: 1000 }] },
        { title: "Longish", variants: [{ length: Reading.time("10:00") }] },
        { title: "No length", variants: [{ length: nil }] },
      ],
    },
    :"top speeds" => {
      input: "top 2 speed",
      result: [["Sprint", { amount: 200, days: 1 }], ["Jog", { amount: Reading.time("5:00"), days: 5 }]],
      items: [
        { title: "Walk", experiences: [{ spans: [
          { dates: Date.new(2023,5,1)..Date.new(2023,5,3), amount: 200 },
          { dates: Date.new(2023,5,5)..Date.new(2023,5,15), amount: 200 },
        ] }] },
        { title: "Sprint", experiences: [{ spans: [
          { dates: Date.new(2023,5,1)..Date.new(2023,5,1), amount: 200 },
        ] }] },
        { title: "Jog", experiences: [{ spans: [
          { dates: Date.new(2023,5,1)..Date.new(2023,5,5), amount: Reading.time("5:00") },
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
      result: [["Short", 100], ["Longish", Reading.time("10:00")]],
      items: [
        { title: "Short", variants: [{ length: 100 }] },
        { title: "Encyclopedic", variants: [{ length: 1000 }] },
        { title: "Longish", variants: [{ length: Reading.time("10:00") }] },
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
          { dates: Date.new(2023,5,1)..Date.new(2023,5,5), amount: Reading.time("5:00") },
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



  ## QUERIES: RESULT FORMATTERS
  # Minimal queries testing result formatters.
  @queries[:result_formatters] = {
    :"average length (pages)" => {
      input: "average length",
      result: "200 pages",
      items: [
        { variants: [{ length: 200 }], experiences: [{ variant_index: 0 }] },
      ],
    },
    # :"average length (time)" => {
    #   input: "average length",
    #   result: "5:00 or 200 pages", # assuming 35 pages per hour (the config default)
    #   items: [
    #     { variants: [{ length: Reading.time("5:00") }], experiences: [{ variant_index: 0 }] },
    #   ],
    # },
    :"total items (singular)" => {
      input: "total item",
      result: "1 item",
      items: [
        {},
      ],
    },
    :"total items (plural)" => {
      input: "total item",
      result: "2 items",
      items: [
        {},
        {},
      ],
    },
    :"total amount" => {
      input: "total amount",
      result: "2 pages",
      items: [
        { experiences: [{ spans: [{ amount: 2 }] }] },
      ],
    },
    :"total amount (zero)" => {
      input: "total amount",
      result: "0 pages",
      items: [
        { experiences: [] },
      ],
    },
    :"top lengths" => {
      input: "top 2 length",
      result: "1. Encyclopedic\n     1000 pages\n2. Short\n     100 pages",
      items: [
        { title: "Short", variants: [{ length: 100 }] },
        { title: "Encyclopedic", variants: [{ length: 1000 }] },
      ],
    },
    # :"top speeds" => {
    #   input: "top 2 speed",
    #   # assuming 35 pages per hour (the config default)
    #   result: "1. Sprint\n     200 pages in 1 day\n2. Jog\n     5:00 or 200 pages in 5 days",
    #   items: [
    #     { title: "Sprint", experiences: [{ spans: [
    #       { dates: Date.new(2023,5,1)..Date.new(2023,5,1), amount: 200 },
    #     ] }] },
    #     { title: "Jog", experiences: [{ spans: [
    #       { dates: Date.new(2023,5,1)..Date.new(2023,5,5), amount: Reading.time("5:00") },
    #     ] }] },
    #   ],
    # },
    # :"bottom lengths" => {
    #   input: "bottom 2 length",
    #   # assuming 35 pages per hour (the config default)
    #   result: "1. Short\n     100 pages\n2. Longish\n     10:00 or 400 pages",
    #   items: [
    #     { title: "Short", variants: [{ length: 100 }] },
    #     { title: "Longish", variants: [{ length: Reading.time("10:00") }] },
    #   ],
    # },
    :"bottom speeds" => {
      input: "bottom 2 speed",
      result: "1. Walk\n     400 pages in 14 days\n2. DNF\n     30 pages in 1 day",
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

  queries[:operations].each do |key, hash|
    define_method("test_operation_#{key}") do
      items = hash.fetch(:items).map { |item_hash|
        Reading::Item.new(
          item_hash,
          config:,
          view: false,
        )
      }

      exp = hash.fetch(:result)
      act = Reading.stats(input: hash.fetch(:input), items:)
      # debugger unless exp == act

      assert_equal exp, act,
        "Unexpected result #{act} from stats query \"#{name}\""

      # Alternate input style: pluralize the second word.
      act = Reading.stats(input: "#{hash.fetch(:input)}s", items:)
      assert_equal exp, act
    end
  end

  queries[:result_formatters].each do |key, hash|
    define_method("test_result_formatter_#{key}") do
      items = hash.fetch(:items).map { |item_hash|
        Reading::Item.new(
          item_hash,
          config:,
          view: false,
        )
      }

      exp = hash.fetch(:result)
      act = Reading.stats(input: hash.fetch(:input), items:, result_formatters: true)
      # debugger unless exp == act
      assert_equal exp, act,
        "Unexpected result #{act} from stats query \"#{name}\""
    end
  end
end
