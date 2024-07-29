$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "test_helpers/test_helper"

require "reading"
require "reading/item"

class FilterTest < Minitest::Test
  describe "Reading::filter" do
    should "filter Items without changing the original array" do
      original_item_count = ITEMS.count

      Reading.filter(items: ITEMS.values, minimum_rating: 4)

      assert_equal original_item_count, ITEMS.count
    end

    should "sort Items by date" do
      filtered = Reading.filter(items: ITEMS.values, minimum_rating: 1)
      sorted_first_two = ITEMS.slice(:ok_scifi_done, :bad_scifi_done).values
      sorted_items = sorted_first_two + ITEMS.except(:bad_scifi_done, :ok_scifi_done).values

      assert_equal sorted_items, filtered
    end

    context "when the :items keyword argument is missing" do
      should "raise an error" do
        assert_raises ArgumentError do
          Reading.filter(minimum_rating: 4)
        end
      end
    end

    context "when no filter keyword argument is provided" do
      should "raise an error" do
        assert_raises ArgumentError do
          Reading.filter(items: ITEMS.values)
        end
      end
    end

    context "when an unrecognized filter keyword argument is provided" do
      should "raise an error" do
        assert_raises ArgumentError do
          Reading.filter(items: ITEMS.values, teh: "lulz")
        end
      end
    end

    context "when the :minimum_rating keyword argument is provided" do
      should "filter Items by minimum rating" do
        filtered = Reading.filter(items: ITEMS.values, minimum_rating: 4)
        remaining = ITEMS.except(:bad_scifi_done, :ok_scifi_done).values

        assert_equal remaining, filtered
      end
    end

    context "when the :excluded_genres keyword argument is provided" do
      should "filter Items by excluded genres" do
        filtered = Reading.filter(items: ITEMS.values, excluded_genres: ["fiction"])
        remaining = ITEMS.slice(:good_science_in_progress, :good_science_planned, :great_science_planned).values

        assert_equal remaining, filtered
      end
    end

    context "when the :status keyword argument is provided" do
      should "filter Items by one status" do
        filtered = Reading.filter(items: ITEMS.values, status: :in_progress)
        remaining = ITEMS.slice(:good_science_in_progress).values

        assert_equal remaining, filtered
      end

      should "filter Items by multiple statuses" do
        filtered = Reading.filter(items: ITEMS.values, no_sort: true, status: [:done, :in_progress])
        remaining = ITEMS.slice(:bad_scifi_done, :ok_scifi_done, :good_science_in_progress).values

        assert_equal remaining, filtered
      end
    end

    context "when multiple filter keyword arguments are provided" do
      should "filter Items by multiple filters" do
        filtered = Reading.filter(
          items: ITEMS.values,
          minimum_rating: 5,
          excluded_genres: ["science"],
          status: :planned,
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
