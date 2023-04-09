$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "test_helper"

require "reading/item"
require "reading/config"
require "reading/util/hash_deep_merge"
require "reading/util/hash_array_deep_fetch"
require "reading/util/hash_to_data"
require "reading"

class ItemTest < Minitest::Test
  using Reading::Util::HashDeepMerge
  using Reading::Util::HashArrayDeepFetch
  using Reading::Util::HashToData

  # The shoulda-context gem provides `context` and `should` blocks. I like
  # RSpec-style `describe` in addition to `context`, and `it` instead of `should`.
  class << self
    alias_method :describe, :context
    alias_method :it, :should
  end

  # But wait, doesn't minitest/spec already provide `describe` blocks? Yes, but
  # I get errors when using it alongside shoulda-context, so here I undefine it
  # so that the alias above (`context` to `describe`) works correctly.
  #
  # (Sidenote: Why is `describe` already defined, but not `it`? It's because
  # `describe` is monkey-patched into Kernel in minitest/spec, which is loaded
  # into minitest/autorun, which I'm using. `it` is also defined in minitest/spec,
  # but within Minitest::Spec which makes it apply only within a Minitest::Spec
  # (which `describe` sets up). See
  # https://github.com/minitest/minitest/blob/master/lib/minitest/spec.rb
  module ::Kernel
    undef describe
  end

  def book(merge_type = :deep_merge, config: {}, **merge_hash)
    Reading::Item.new(BOOK.send(merge_type, merge_hash), config: full_config(config))
  end

  def podcast(merge_type = :deep_merge, config: {}, **merge_hash)
    Reading::Item.new(PODCAST.send(merge_type, merge_hash), config: full_config(config))
  end

  def full_config(custom_config = {})
    Reading::Config.new(custom_config).hash
  end

  describe "any attribute from the item hash" do
    it "can be accessed" do
      # Convert to Data and back again because #to_data converts nested Hashes
      # to Datas, but #to_h converts only the top level back to a Hash.
      BOOK.to_data.to_h.each do |key, value|
        assert_equal value, book.send(key)
      end

      PODCAST.to_data.to_h.each do |key, value|
        debugger if value.nil?
        assert_equal value, podcast.send(key)
      end
    end
  end

  describe "#status" do
    context "when there aren't any spans" do
      it "is :planned" do
        planned_book = book(:merge, experiences: [])

        assert_equal :planned, planned_book.status
      end
    end

    context "when there are spans" do
      context "when there's no end date in the last span" do
        it "is :in_progress" do
          in_progress_book = book

          assert_equal :in_progress, in_progress_book.status
        end
      end

      context "when there is an end date in the last span" do
        it "is :done" do
          done_date_range = Date.new(2020,12,23)..Date.new(2021,2,10)
          done_book = book(experiences: [{}, {}, { spans: [{}, { dates: done_date_range }] }])

          assert_equal :done, done_book.status
        end
      end
    end
  end # #status

  describe "#view" do
    describe "custom view" do
      context "when the custom view is nil or false" do
        it "isn't built" do
          book_without_view = Reading::Item.new(BOOK, view: false)

          assert_nil book_without_view.view
        end
      end

      context "when the custom view is a custom class" do
        it "is built via that class" do
          custom_view = Class.new do
            def initialize(item, config)
            end

            def something_custom
              "shiny customization"
            end
          end
          book_with_custom_view = Reading::Item.new(BOOK, view: custom_view)

          assert "shiny customization", book_with_custom_view.view.something_custom
        end
      end
    end

    describe "#name" do
      context "when a variant has an ISBN/ASIN or URL" do
        context "when the second variant has both, the first has neither" do
          it "is from the second variant" do
            book_without_first_isbn = book(variants: [{ isbn: nil }])
            second_name = "Tom Holt – The Walled Orchard 〜 in Holt's Classical Novels 〜 " \
              "The Walled Orchard Series, #2 〜 1991 〜 out of print"

            assert_equal second_name, book_without_first_isbn.view.name
          end
        end

        context "when the first variant has a URL, the second has an ISBN" do
          it "is from the first variant" do
            book_with_first_url = book(variants: [{ isbn: nil, sources: [{ url: "https://example.com" }] }])
            first_name = "Tom Holt – The Walled Orchard 〜 in Holt's Classical Novels 〜 " \
              "2009 〜 both volumes in one"

            assert_equal first_name, book_with_first_url.view.name
          end
        end
      end

      context "when no variants have an ISBN/ASIN or URL" do
        context "when there is at least one variant" do
          it "is from the first variant by default" do
            book_without_isbns_or_urls = book(
              variants: [{ isbn: nil },
                         { isbn: nil, sources: [{}, { url: nil }] }],
            )
            first_name = "Tom Holt – The Walled Orchard 〜 in Holt's Classical Novels 〜 " \
              "2009 〜 both volumes in one"

            assert_equal first_name, book_without_isbns_or_urls.view.name
          end
        end

        context "when there are no variants" do
          it "is the author and title only" do
            book_without_variants = book(:merge, variants: [])
            basic_name = "Tom Holt – The Walled Orchard"

            assert_equal basic_name, book_without_variants.view.name
          end
        end
      end
    end # #view#name

    describe "#rating" do
      context "when below the star minimum" do
        it "is nil" do
          assert_nil book.view.rating
        end
      end

      context "when equal to or above the star minimum" do
        it "is a star" do
          book_5_star = book(rating: 5)

          assert_equal "⭐", book_5_star.view.rating
        end
      end

      context "when the star minimum is nil" do
        it "is the item's rating" do
          book_no_stars = book(config: { item_view: { minimum_rating_for_star: nil } })

          assert_equal book_no_stars.rating, book_no_stars.view.rating
        end
      end
    end # #view#rating

    describe "#type_emoji" do
      context "when the item has a format" do
        it "is determined by the format" do
          assert_equal "📕", book.view.type_emoji
        end
      end

      context "when the item doesn't have a format" do
        it "is the default type emoji" do
          config = Reading::Config.new.hash
          podcast = podcast(config:, variants: [{ format: nil }])
          default_type = config.deep_fetch(:item_view, :default_type)
          default_type_emoji = config.deep_fetch(:item_view, :types, default_type, :emoji)

          assert_equal default_type_emoji, podcast.view.type_emoji
        end
      end
    end # #view#type_emoji

    describe "#genres" do
      it "is the item's genres" do
        assert_equal book.genres, book.view.genres
      end
    end # #view#genres

    describe "#status" do
      it "is the item's status stringified" do
        assert_equal "in progress", book.view.status
      end
    end # #view#status

    describe "#date" do
      context "when the item is done" do
        it "is the last end date" do
          done_date_range = Date.new(2020,12,23)..Date.new(2021,2,10)
          done_book = book(experiences: [{}, {}, { spans: [{}, { dates: done_date_range }] }])

          assert_equal '2021-02-10', done_book.view.date
        end
      end

      context "when the item is in progress or planned" do
        it "is nil" do
          in_progress_book = book
          planned_book = book(:merge, experiences: [])

          assert_nil in_progress_book.view.date
          assert_nil planned_book.view.date
        end
      end
    end # #view#date

    describe "#isbn" do
      context "when a variant has an ISBN/ASIN or URL" do
        context "when the second variant has both, the first has neither" do
          it "is from the second variant" do
            book_without_first_isbn = book(variants: [{ isbn: nil }])

            assert_equal book_without_first_isbn.variants[1].isbn, book_without_first_isbn.view.isbn
          end
        end

        context "when the first variant has a URL, the second has an ISBN" do
          it "is from the first variant" do
            book_with_first_url = book(variants: [{ isbn: nil, sources: [{ url: "https://example.com" }] }])

            assert_nil book_with_first_url.view.isbn
          end
        end
      end

      context "when no variants have an ISBN/ASIN or URL" do
        context "when there is at least one variant" do
          it "is nil" do
            book_without_isbns_or_urls = book(
              variants: [{ isbn: nil },
                         { isbn: nil, sources: [{}, { url: nil }] }],
            )

            assert_nil book_without_isbns_or_urls.view.isbn
          end
        end

        context "when there are no variants" do
          it "is nil" do
            book_without_variants = book(:merge, variants: [])

            assert_nil book_without_variants.view.isbn
          end
        end
      end
    end # #view#isbn

    describe "#url" do
      context "when a variant has an ISBN/ASIN or URL" do
        context "when the second variant has both, the first has neither" do
          it "is from the second variant's ISBN" do
            config = Reading::Config.new.hash
            book_without_first_isbn = book(config:, variants: [{ isbn: nil }])
            url_from_isbn = config
              .deep_fetch(:item_view, :url_from_isbn)
              .sub('%{isbn}', book_without_first_isbn.variants[1].isbn)

            assert_equal url_from_isbn, book_without_first_isbn.view.url
          end
        end

        context "when the first variant has a URL, the second has an ISBN" do
          it "is from the first variant's first URL" do
            book_with_first_url = book(variants: [{ isbn: nil, sources: [{ url: "https://example.com" }] }])

            assert_equal book_with_first_url.variants.first.sources.first.url, book_with_first_url.view.url
          end
        end
      end

      context "when no variants have an ISBN/ASIN or URL" do
        context "when there is at least one variant" do
          it "is nil" do
            book_without_isbns_or_urls = book(
              variants: [{ isbn: nil },
                         { isbn: nil, sources: [{}, { url: nil }] }],
            )

            assert_nil book_without_isbns_or_urls.view.url
          end
        end

        context "when there are no variants" do
          it "is nil" do
            book_without_variants = book(:merge, variants: [])

            assert_nil book_without_variants.view.url
          end
        end
      end
    end # #view#url

    describe "#experience_count" do
      it "is the number of the item's experiences" do
        assert_equal book.experiences.count, book.view.experience_count
      end
    end # #view#experience_count

    describe "#groups" do
      it "is all the item's groups" do
        assert_equal ["classics book club", "with Hannah"], book.view.groups
      end
    end # #view#groups

    describe "#blurb" do
      it "is the first blurb note" do
        assert_equal "My favorite historical fiction.", book.view.blurb
      end
    end # #view#blurb

    describe "#public_notes" do
      it "is all the public, non-blurb notes" do
        public_notes = ["Others by Holt that I should try: A Song for Nero, Alexander at the World's End."]
        assert_equal public_notes, book.view.public_notes
      end
    end # #view#public_notes
  end # #view

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
          extra_info: ["2009", "both volumes in one"],
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
          extra_info: ["1991", "out of print"],
        }],
      experiences:
        [{
          spans:
            [{
              dates: Date.new(2018,2,10)..Date.new(2018,5,3),
              progress: 1.0,
              amount: 480,
              name: nil,
              favorite?: false,
            }],
          group: "classics book club",
          variant_index: 0,
        },
        {
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
          content: "Got sidetracked in the re-read.",
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
