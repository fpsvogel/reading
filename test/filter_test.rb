$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "test_helpers/test_helper"
require_relative "test_helpers/describe_and_it_blocks"

require "reading/filter"
require "reading/item"

class FilterTest < Minitest::Test
  extend DescribeAndItBlocks

  describe "::by" do
    it "filters Items without changing the original array" do
      original_item_count = ITEMS.count

      Reading::Filter.by(minimum_rating: 4, items: ITEMS.values)

      assert_equal original_item_count, ITEMS.count
    end

    it "sorts Items by date" do
      filtered = Reading::Filter.by(minimum_rating: 1, items: ITEMS.values)
      sorted_first_two = ITEMS.slice(:ok_scifi_done, :bad_scifi_done).values
      sorted_items = sorted_first_two + ITEMS.except(:bad_scifi_done, :ok_scifi_done).values

      assert_equal sorted_items, filtered
    end

    context "when the :items keyword argument is missing" do
      it "raises an error" do
        assert_raises ArgumentError do
          Reading::Filter.by(minimum_rating: 4)
        end
      end
    end

    context "when no filter keyword argument is provided" do
      it "raises an error" do
        assert_raises ArgumentError do
          Reading::Filter.by(items: ITEMS.values)
        end
      end
    end

    context "when an unrecognized filter keyword argument is provided" do
      it "raises an error" do
        assert_raises ArgumentError do
          Reading::Filter.by(teh: "lulz", items: ITEMS.values)
        end
      end
    end

    context "when the :minimum_rating keyword argument is provided" do
      it "filters Items by minimum rating" do
        filtered = Reading::Filter.by(minimum_rating: 4, items: ITEMS.values)
        remaining = ITEMS.except(:bad_scifi_done, :ok_scifi_done).values

        assert_equal remaining, filtered
      end
    end

    context "when the :excluded_genres keyword argument is provided" do
      it "filters Items by excluded genres" do
        filtered = Reading::Filter.by(excluded_genres: ["fiction"], items: ITEMS.values)
        remaining = ITEMS.slice(:good_science_in_progress, :good_science_planned, :great_science_planned).values

        assert_equal remaining, filtered
      end
    end

    context "when the :status keyword argument is provided" do
      it "filters Items by one status" do
        filtered = Reading::Filter.by(status: :in_progress, items: ITEMS.values)
        remaining = ITEMS.slice(:good_science_in_progress).values

        assert_equal remaining, filtered
      end

      it "filters Items by multiple statuses" do
        filtered = Reading::Filter.by(status: [:done, :in_progress], items: ITEMS.values, no_sort: true)
        remaining = ITEMS.slice(:bad_scifi_done, :ok_scifi_done, :good_science_in_progress).values

        assert_equal remaining, filtered
      end
    end

    context "when multiple filter keyword arguments are provided" do
      it "filters Items by multiple filters" do
        filtered = Reading::Filter.by(
          minimum_rating: 5,
          excluded_genres: ["science"],
          status: :planned,
          items: ITEMS.values,
        )
        remaining = ITEMS.slice(:great_fiction_planned).values

        assert_equal remaining, filtered
      end
    end
  end

  private

  ITEMS = {
    bad_scifi_done: Reading::Item.new(
      {
        rating: 1,
        genres: ["science", "fiction"],
        experiences:
          [{
            spans:
              [{
                dates: Date.new(2019,2,10)..Date.new(2019,5,3),
                progress: 1.0,
                amount: nil,
                name: nil,
                favorite?: false,
              }],
            group: nil,
            variant_index: 0,
          }],
      }
    ),
    ok_scifi_done: Reading::Item.new(
      {
        rating: 3,
        genres: ["science", "fiction"],
        experiences:
          [{
            spans:
              [{
                dates: Date.new(2018,2,10)..Date.new(2018,5,3),
                progress: 1.0,
                amount: nil,
                name: nil,
                favorite?: false,
              }],
            group: nil,
            variant_index: 0,
          }],
      }
    ),
    good_science_in_progress: Reading::Item.new(
      {
        rating: 4,
        genres: ["science"],
        experiences:
          [{
            spans:
              [{
                dates: Date.new(2018,2,10)..,
                progress: nil,
                amount: nil,
                name: nil,
                favorite?: false,
              }],
            group: nil,
            variant_index: 0,
          }],
      }
    ),
    great_fiction_planned: Reading::Item.new(
      {
        rating: 5,
        genres: ["fiction"],
      }
    ),
    great_science_planned: Reading::Item.new(
      {
        rating: 5,
        genres: ["science"],
      }
    ),
    good_fiction_planned: Reading::Item.new(
      {
        rating: 4,
        genres: ["fiction"],
      }
    ),
  }
end
