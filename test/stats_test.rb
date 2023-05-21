$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "test_helpers/test_helper"

require "reading"

class StatsTest < Minitest::Test
  self.class.attr_reader :items, :queries

  def items = self.class.items

  def inputs = self.class.inputs

  def outputs = self.class.outputs

  # ==== ITEMS

  config = Reading::Config.new.hash

  item_hashes = [
    {
      rating: 3,
      variants: [
        { length: 200 },
      ],
    },
    {
      rating: 5,
      variants: [
        { length: 300 },
      ],
    },
  ]

  @items = item_hashes.map { |item_hash|
    Reading::Item.new(
      item_hash,
      config:,
      view: false,
    )
  }

  # ==== TEST QUERIES AND RESULTS

  @queries = {}

  ## QUERIES: OPERATIONS
  # Simple queries testing each operation, without filters or group-by.
  @queries[:operations] =
  {
  "average rating" =>
    4.0,
  "average length" =>
    0,
  # "average amount" =>
  #   nil,
  "count" =>
    2,
  }

  # ==== TESTS

  queries[:operations].each do |query, result|
    define_method("test_operation_#{query}") do
      exp = result
      act = Reading.stats(input: query, items:, config:)
      # debugger unless exp == act
      assert_equal exp, act,
        "Unexpected result from stats query: #{name}"
    end
  end
end
