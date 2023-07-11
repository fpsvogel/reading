$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative 'test_helpers/test_helper'
require_relative 'test_helpers/describe_and_it_blocks'

require 'reading/item'
require 'reading'

class ItemTest < Minitest::Test
  extend DescribeAndItBlocks

  using Reading::Util::HashDeepMerge
  using Reading::Util::HashArrayDeepFetch
  using Reading::Util::HashToData

  def book(merge_type = :deep_merge, config: {}, **merge_hash)
    Reading::Item.new(BOOK.send(merge_type, merge_hash), config: full_config(config))
  end

  def podcast(merge_type = :deep_merge, config: {}, **merge_hash)
    Reading::Item.new(PODCAST.send(merge_type, merge_hash), config: full_config(config))
  end

  def full_config(custom_config = {})
    Reading::Config.hash(custom_config)
  end

  describe "#split" do
    context "with a planned Item" do
      it "returns an empty array" do
        item = Reading::Item.new({ title: "Planning for Dummies", experiences: [] })
        any_date = Date.new(2022,1,1)

        assert_equal [], item.split(any_date)
      end
    end

    context "with the book example" do
      context "when the date is within an in-progress experience with only one span" do
        it "returns the original Item" do
          item = book
          split_at = Date.new(2021,1,1)

          assert_equal [nil, item], item.split(split_at)
        end
      end

      context "when the date is before all experiences" do
        it "returns the original Item" do
          item = book
          split_at = Date.new(2018,2,1)

          assert_equal [nil, item], item.split(split_at)
        end
      end

      context "when the date is after all experiences and they are all done" do
        it "returns the original Item" do
          done_experiences = BOOK[:experiences][..1]
          item = book(:merge, experiences: done_experiences)
          split_at = Date.new(2019,7,1)

          assert_equal [item, nil], item.split(split_at)
        end
      end

      context "when the date is between experiences" do
        it "returns two Items with experiences before/after the given date" do
          item = book
          split_at = Date.new(2018,6,1)
          split_item_a, split_item_b = item.split(split_at)

          expected_experiences_a = [item.experiences.first]
          expected_variants_a = [item.variants.first]

          expected_experiences_b = item.experiences[1..]
          expected_variants_b = item.variants

          assert_equal expected_experiences_a, split_item_a.experiences
          assert_equal expected_variants_a, split_item_a.variants

          assert_equal expected_experiences_b, split_item_b.experiences
          assert_equal expected_variants_b, split_item_b.variants
        end
      end

      context "when the date is within a done experience" do
        it "returns two Items with experiences before/after the given date" do
          item = book
          split_at = Date.new(2019,6,1)
          split_item_a, split_item_b = item.split(split_at)

          mid_span = item.experiences[1].spans.first
          expected_experiences_a = [
            item.experiences[0].to_h,
            item.experiences[1].to_h.merge(
              spans: [mid_span.to_h.merge(
                dates: mid_span.dates.begin..split_at.prev_day,
                amount: mid_span.amount * (31/41.0),
              )],
              last_end_date: split_at.prev_day,
            ),
          ]
          expected_variants_a = [item.variants.first]

          expected_experiences_b = [
            item.experiences[1].to_h.merge(
              spans: [mid_span.to_h.merge(
                dates: split_at..mid_span.dates.end,
                amount: mid_span.amount * (10/41.0),
              )],
            ),
            item.experiences[2].to_h,
          ]
          expected_variants_b = item.variants

          assert_equal expected_experiences_a.map(&:to_data),
            split_item_a.experiences
          assert_equal expected_variants_a, split_item_a.variants

          assert_equal expected_experiences_b.map(&:to_data),
            split_item_b.experiences
          assert_equal expected_variants_b, split_item_b.variants
        end
      end
    end

    context "with the podcast example" do
      context "when the date is within an in-progress span" do
        it "returns the original Item" do
          last_span = PODCAST[:experiences].first[:spans].last
          in_progress_last_span = last_span.merge(dates: last_span[:dates].begin..)
          item = podcast(experiences: [
            { spans: [
              *([{}] * (PODCAST[:experiences].first[:spans].count - 1)),
              in_progress_last_span,
            ]},
          ])
          split_at = last_span[:dates].begin

          assert_equal [nil, item], item.split(split_at)
        end
      end

      context "when the date is before all spans" do
        it "returns the original Item" do
          item = podcast
          split_at = Date.new(2021,10,1)

          assert_equal [nil, item], item.split(split_at)
        end
      end

      context "when the date is after all spans and they are all done or planned" do
        it "returns the original Item" do
          item = podcast
          split_at = Date.new(2022,2,1)

          assert_equal [item, nil], item.split(split_at)
        end
      end

      context "when the date is between spans" do
        it "returns two Items with experiences before/after the given date" do
          item = podcast(title: 'lol')
          split_at = Date.new(2021,11,14)
          split_item_a, split_item_b = item.split(split_at)

          before_span_index = 4
          before_span = item.experiences[0].spans[before_span_index]
          expected_experiences_a = [
            item.experiences[0].to_h.merge(
              spans: item.experiences[0].spans[..before_span_index],
              last_end_date: before_span.dates.end,
            ),
          ]

          expected_experiences_b = [
            item.experiences[0].to_h.merge(
              spans: item.experiences[0].spans[(before_span_index + 1)..],
            ),
          ]

          assert_equal expected_experiences_a.map(&:to_data),
            split_item_a.experiences

          assert_equal expected_experiences_b.map(&:to_data),
            split_item_b.experiences
        end
      end

      context "when the date is within a done span" do
        it "returns two Items with experiences before/after the given date" do
          item = podcast
          split_at = Date.new(2021,11,1)
          split_item_a, split_item_b = item.split(split_at)

          mid_span_index = 4
          mid_span = item.experiences[0].spans[mid_span_index]
          expected_experiences_a = [
            item.experiences[0].to_h.merge(
              spans: [
                *item.experiences[0].spans[..(mid_span_index - 1)].map(&:to_h),
                mid_span.to_h.merge(
                  dates: mid_span.dates.begin..split_at.prev_day,
                  amount: mid_span.amount * (7/19.0),
                ),
              ],
              last_end_date: split_at.prev_day,
            ),
          ]

          expected_experiences_b = [
            item.experiences[0].to_h.merge(
              spans: [
                mid_span.to_h.merge(
                  dates: split_at..mid_span.dates.end,
                  amount: mid_span.amount * (12/19.0),
                ),
                *item.experiences[0].spans[(mid_span_index + 1)..].map(&:to_h)
              ],
            ),
          ]

          assert_equal expected_experiences_a.map(&:to_data),
            split_item_a.experiences

          assert_equal expected_experiences_b.map(&:to_data),
            split_item_b.experiences
        end
      end
    end
  end

  describe "any attribute from the item hash" do
    it "can be accessed" do
      items = { BOOK => book, PODCAST => podcast }

      items.each do |hash, item|
        # Convert to Data and back again because #to_data converts nested Hashes
        # to Datas, but #to_h converts only the top level back to a Hash.
        hash.to_data.to_h.each do |key, value|
          item_value = item.send(key)

          # :experiences is the only place where the item's data adds keys
          # (:status and :last_end_date) to the original hash.
          if key == :experiences
            value = value.map.with_index { |experience, i|
              experience.to_h.merge(
                status: item_value[i].status,
                last_end_date: item_value[i].last_end_date,
              ).to_data
            }
          end

          assert_equal value, item_value
        end
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
      context "when the Item has a definite length" do
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

      context "when the Item has an indefinite length" do
        context "when the in-progress grace period is over" do
          it "is :done" do
            assert_equal :done, podcast.status
          end
        end

        # Date::today is stubbed in test_helper.rb to 2022/10/1
        context "when the in-progress grace period is not yet over" do
          it "is :in_progress" do
            podcast_with_recent_listen = podcast(experiences: [
              { spans: [
                *([{}] * PODCAST[:experiences].first[:spans].count),
                { dates: Date.new(2022,9,15)..Date.new(2022,9,15) },
              ]},
            ])

            assert_equal :in_progress, podcast_with_recent_listen.status
          end
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
    end # #view custom view

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
          book_no_stars = book(config: { item: { view: { minimum_rating_for_star: nil } } })

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
          config = Reading.default_config
          podcast = podcast(config:, variants: [{ format: nil }])
          default_type = config.deep_fetch(:item, :view, :default_type)
          default_type_emoji = config.deep_fetch(:item, :view, :types, default_type, :emoji)

          assert_equal default_type_emoji, podcast.view.type_emoji
        end
      end
    end # #view#type_emoji

    describe "#genres" do
      it "is the item's genres" do
        assert_equal book.genres, book.view.genres
      end
    end # #view#genres

    describe "#date_or_status" do
      context "when the item is done" do
        it "is the last end date as a string" do
          done_date_range = Date.new(2020,12,23)..Date.new(2021,2,10)
          done_book = book(experiences: [{}, {}, { spans: [{}, { dates: done_date_range }] }])

          assert_equal '2021-02-10', done_book.view.date_or_status
        end
      end

      context "when the item is in progress or planned" do
        it "is nil" do
          in_progress_book = book
          planned_book = book(:merge, experiences: [])

          assert_equal 'in progress', in_progress_book.view.date_or_status
          assert_equal 'planned', planned_book.view.date_or_status
        end
      end
    end # #view#date_or_status

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
            config = Reading.default_config
            book_without_first_isbn = book(config:, variants: [{ isbn: nil }])
            url_from_isbn = config
              .deep_fetch(:item, :view, :url_from_isbn)
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
              dates: Date.new(2021,10,6)..Date.new(2021,10,10),
              progress: 1.0,
              amount: Reading.time('8:00'),
              name: nil,
              favorite?: false,
            },
            {
              dates: Date.new(2021,10,11)..Date.new(2021,10,17),
              progress: 1.0,
              amount: Reading.time('1:00'),
              name: nil,
              favorite?: false,
            },
            {
              dates: Date.new(2021,10,18)..Date.new(2021,10,24),
              progress: 1.0,
              amount: Reading.time('3:00'),
              name: nil,
              favorite?: false,
            },
            {
              dates: nil,
              progress: nil,
              amount: Reading.time('1:00'),
              name: "The Amish",
              favorite?: false,
            },
            {
              dates: Date.new(2021,10,25)..Date.new(2021,11,12),
              progress: 1.0,
              amount: Reading.time('2:00'),
              name: nil,
              favorite?: false,
            },
            {
              dates: Date.new(2021,11,14)..Date.new(2021,11,14),
              progress: 1.0,
              amount: Reading.time('0:50'),
              name: "#30 Leaf Blowers",
              favorite?: true,
            },
            {
              dates: Date.new(2021,11,15)..Date.new(2021,11,15),
              progress: Reading.time('0:15'),
              amount: Reading.time('1:00'),
              name: "Baseball",
              favorite?: false,
            },
            {
              dates: Date.new(2021,11,15)..Date.new(2021,11,15),
              progress: 1.0,
              amount: Reading.time('3:00'),
              name: nil,
              favorite?: false,
            },
            {
              dates: nil,
              progress: nil,
              amount: Reading.time('1:00'),
              name: "#32 Soft Drinks",
              favorite?: false,
            },
            {
              dates: nil,
              progress: nil,
              amount: Reading.time('1:00'),
              name: "Christmas",
              favorite?: false,
            },
            {
              dates: Date.new(2022,1,1)..Date.new(2022,1,1),
              progress: 1.0,
              amount: Reading.time('1:00'),
              name: "New Year's",
              favorite?: false,
            }],
          group: nil,
          variant_index: 0,
        }],
      notes: [],
    }
end
