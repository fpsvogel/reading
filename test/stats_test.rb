$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "test_helpers/test_helper"

require "reading"

class StatsTest < Minitest::Test
  self.class.attr_reader :queries, :config

  def config = self.class.config

  @config = Reading::Config.new.hash

  # ==== TEST QUERIES

  @queries = {}

  ## QUERIES: OPERATIONS
  # Simple queries testing each operation, without filters or group-by.
  @queries[:operations] = {
    :"average rating" => {
      input: "average rating",
      result: 3.5,
      items: [
        { rating: 3 },
        { rating: 4 },
      ],
    },
    :"average rating with nil" => {
      input: "average rating",
      result: 3.0,
      items: [
        { rating: 3 },
        { rating: nil },
      ],
    },
    :"average length" => {
      input: "average length",
      result: 250,
      items: [
        { variants: [{ length: 200 }], experiences: [{ variant_index: 0 }] },
        { variants: [{ length: 300 }], experiences: [{ variant_index: 0 }] },
      ],
    },
    :"average length with pages and time lengths" => {
      input: "average length",
      result: 180,
      items: [
        { variants: [{ length: 200 }], experiences: [{ variant_index: 0 }] },
        { variants: [{ length: Reading.time('4:00') }], experiences: [{ variant_index: 0 }] },
      ],
    },
    :"average length with time and pages lengths" => {
      input: "average length",
      result: 180,
      items: [
        { variants: [{ length: Reading.time('4:00') }], experiences: [{ variant_index: 0 }] },
        { variants: [{ length: 200 }], experiences: [{ variant_index: 0 }] },
      ],
    },
    :"count" => {
      input: "count",
      result: 2,
      items: [
        {},
        {},
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
      act = Reading.stats(input: hash.fetch(:input), items:, config:)
      # debugger unless exp == act

      assert_equal exp, act,
        "Unexpected result #{act} from stats query: #{name}"
    end
  end
end
