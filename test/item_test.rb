$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "test_helper"

require "reading/item"
require "reading/util/hash_to_struct"
require "reading"

class ItemTest < Minitest::Test
  using Reading::Util::HashToStruct

  def test_all_item_attributes_can_be_accessed
    item = Reading::Item.new(BOOK)

    # Convert to Struct and back again because #to_struct converts nested Hashes
    # to Structs, but #to_h converts only the top level back to a Hash.
    BOOK.to_struct.to_h.each do |key, value|
      assert_equal value, item.send(key)
    end
  end

  private

  BOOK =
    {
      rating: 4,
      author: "Tom Holt",
      title: "The Walled Orchard",
      genres: ["fiction", "history"],
      variants:
        [{
          format: :ebook,
          series:
            [{
              name: "Holt's Classical Novels",
              volume: nil,
            }],
          sources:
            [{
              name: "Lexpub",
              url: nil,
            }],
          isbn: "B00GVG01HE",
          length: 591,
          extra_info: ["2009"],
        },
        {
          format: :print,
          series:
            [{
              name: "Holt's Classical Novels",
              volume: nil,
            },
            {
              name: "The Walled Orchard Series",
              volume: 2,
            }],
          sources:
            [{
              name: "Little Library",
              url: nil,
            },
            {
              name: "Internet Archive",
              url: "https://archive.org/details/walledorchard00holt",
            }],
          isbn: "0312038380",
          length: 247,
          extra_info: ["1991"],
        }],
      experiences:
        [{
          spans:
            [{
              dates: Date.new(2019,5,1)..Date.new(2019,6,10),
              progress: 0.7,
              amount: 480,
              name: nil,
              favorite?: false,
            }],
          group: nil,
          variant_index: 0,
        },
        {
          spans:
            [{
              dates: Date.new(2020,12,23)..,
              progress: nil,
              amount: nil,
              name: nil,
              favorite?: false,
            }],
          group: "with Hannah",
          variant_index: 1,
        }],
      notes:
        [{
          blurb?: false,
          private?: true,
          content: "Got sidetracked in my first time reading it.",
        },
        {
          blurb?: true,
          private?: false,
          content: "My favorite historical fiction.",
        },
        {
          blurb?: false,
          private?: false,
          content: "Others by Holt that I should try: A Song for Nero, Alexander at the World's End.",
        }],
    }

  PODCAST =
    {
      rating: 3,
      author: nil,
      title: "Flightless Bird",
      genres: ["podcast"],
      variants:
        [{
          format: :audio,
          series: [],
          sources:
            [{
              name: "Spotify",
              url: nil,
            },
            {
              name: nil,
              url: "https://armchairexpertpod.com/flightless-bird",
            }],
          isbn: nil,
          length: nil,
          extra_info: [],
        }],
      experiences:
        [{
          spans:
            [{
              dates: Date.new(2022,10,6)..Date.new(2022,10,10),
              progress: 1.0,
              amount: "8:00",
              name: nil,
              favorite?: false,
            }],
          group: nil,
          variant_index: 0,
        },
        {
          spans:
            [{
              dates: Date.new(2022,10,11)..Date.new(2022,11,17),
              progress: 1.0,
              amount: "1:00",
              name: nil,
              favorite?: false,
            }],
          group: nil,
          variant_index: 0,
        },
        {
          spans:
            [{
              dates: Date.new(2022,10,18)..Date.new(2022,10,24),
              progress: 1.0,
              amount: "3:00",
              name: nil,
              favorite?: false,
            }],
          group: nil,
          variant_index: 0,
        },
        {
          spans:
            [{
              dates: Date.new(2022,10,25)..Date.new(2022,11,12),
              progress: 1.0,
              amount: "2:00",
              name: nil,
              favorite?: false,
            }],
          group: nil,
          variant_index: 0,
        },
        {
          spans:
            [{
              dates: Date.new(2022,11,14)..Date.new(2022,11,14),
              progress: 1.0,
              amount: "0:50",
              name: "#30 Leaf Blowers",
              favorite?: true,
            }],
          group: nil,
          variant_index: 0,
        },
        {
          spans:
            [{
              dates: Date.new(2022,11,15)..Date.new(2022,11,15),
              progress: Reading.time("0:15"),
              amount: "1:00",
              name: "Baseball",
              favorite?: false,
            }],
          group: nil,
          variant_index: 0,
        },
        {
          spans:
            [{
              dates: Date.new(2022,11,15)..Date.new(2022,11,15),
              progress: 1.0,
              amount: "3:00",
              name: nil,
              favorite?: false,
            }],
          group: nil,
          variant_index: 0,
        },
        {
          spans:
            [{
              dates: nil,
              progress: nil,
              amount: "1:00",
              name: "#32 Soft Drinks",
              favorite?: false,
            }],
          group: nil,
          variant_index: 0,
        },
        {
          spans:
            [{
              dates: nil,
              progress: nil,
              amount: "1:00",
              name: "Christmas",
              favorite?: false,
            }],
          group: nil,
          variant_index: 0,
        }],
      notes: [],
    }
end
