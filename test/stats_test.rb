$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require_relative 'test_helpers/test_helper'

require 'reading'
require 'reading/stats/terminal_result_formatters'
require 'pastel'

class StatsTest < Minitest::Test
  using Reading::Util::HashArrayDeepFetch

  self.class.attr_reader :queries

  PASTEL = Pastel.new

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
    :"average amount" => {
      input: "average amount",
      # assuming 35 pages per hour (the config default)
      result: Reading.time('1:00'),
      items: [
        { experiences: [{ spans: [{ amount: 17.5 }] },
                        { spans: [{ amount: 17.5 }, { amount: Reading.time('1:00') }] }] },
        { experiences: [{ spans: [{ amount: 35 }] }] },
        { experiences: [] },
      ],
    },
    :"average amount (empty)" => {
      input: "average amount",
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
        { experiences: [{ spans: [{ amount: 17.5, progress: 1.0 }] },
                        { spans: [{ amount: 17.5, progress: 1.0 },
                                  { amount: Reading.time('1:00'), progress: 1.0 }] }] },
        { experiences: [{ spans: [{ amount: 70, progress: 0.5 }] }] },
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
    :"top amounts" => {
      input: "top 2 amount",
      result: [["So much", 140], ["Much", Reading.time('3:00')]],
      items: [
        { title: "Little", experiences: [
          { spans: [{ amount: Reading.time('1:00'), progress: 1.0 }] },
          { spans: [{ amount: 70, progress: 0.5 }] }] },
        { title: "So much", experiences: [{ spans: [{ amount: 140, progress: 1.0 }] }] },
        { title: "Much", experiences: [{ spans: [{ amount: Reading.time('6:00'), progress: 0.5 }] }] },
        { title: "Nothing", experiences: [] },
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
    :"bottom amounts" => {
      input: "bottom 2 amount",
      result: [["Little", 70], ["Much", Reading.time('3:00')]],
      items: [
        { title: "Little", experiences: [
          { spans: [{ amount: Reading.time('1:00'), progress: 1.0 }] },
          { spans: [{ amount: 70, progress: 0.5 }] }] },
        { title: "So much", experiences: [{ spans: [{ amount: 140, progress: 1.0 }] }] },
        { title: "Much", experiences: [{ spans: [{ amount: Reading.time('6:00'), progress: 0.5 }] }] },
        { title: "Nothing", experiences: [] },
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

  # Long enough ago that an item of indefinite length is considered done.
  grace_period = Reading::Config.hash.deep_fetch(
    :item, :indefinite_in_progress_grace_period_days)
  long_ago = (Date.today - grace_period - 1)..(Date.today - grace_period - 1)

  @queries[:filters] = {
    :"rating" => {
      input: "average length rating=3",
      result: 30,
      items: [
        { rating: 3, variants: [{ length: 30 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: nil, variants: [{ length: 100 }] },
      ],
    },
    :"rating (or, none)" => {
      input: "average length rating=3,4,none",
      result: 170/3.0,
      items: [
        { rating: 3, variants: [{ length: 30 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: 5, variants: [{ length: 50 }] },
        { rating: nil, variants: [{ length: 100 }] },
      ],
    },
    :"rating (not, none)" => {
      input: "average length rating!=3,4,none",
      result: 100,
      items: [
        { rating: 3, variants: [{ length: 30 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: 5, variants: [{ length: 100 }] },
        { rating: nil, variants: [{ length: 200 }] },
      ],
    },
    :"rating (greater than)" => {
      input: "average length rating>3",
      result: 40,
      items: [
        { rating: 3, variants: [{ length: 30 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: nil, variants: [{ length: 100 }] },
      ],
    },
    :"rating (greater than or equal to)" => {
      input: "average length rating>=3",
      result: 35,
      items: [
        { rating: 3, variants: [{ length: 30 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: nil, variants: [{ length: 100 }] },
      ],
    },
    :"rating (less than)" => {
      input: "average length rating<4",
      result: 30,
      items: [
        { rating: 3, variants: [{ length: 30 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: nil, variants: [{ length: 100 }] },
      ],
    },
    :"rating (less than or equal to)" => {
      input: "average length rating<=4",
      result: 35,
      items: [
        { rating: 3, variants: [{ length: 30 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: nil, variants: [{ length: 100 }] },
      ],
    },
    # The inverse (e.g. less than 3 and greater than 4) doesn't work because
    # that "and" applies to each rating, and a single rating can't be both less
    # than 3 and greater than 5. Instead do "rating!=3,4". (Or if decimal ratings
    # are in use, "rating!=3,3.5,4", or whatever your decimal intervals are.)
    :"rating (greater than 3, less than 5)" => {
      input: "average length rating>3 rating<5",
      result: 40,
      items: [
        { rating: 3, variants: [{ length: 30 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: 5, variants: [{ length: 100 }] },
        { rating: nil, variants: [{ length: 200 }] },
      ],
    },
    :"done" => {
      input: "average rating done=20%",
      result: 2,
      items: [
        { rating: 2,
          experiences: [{ spans: [{ progress: 0.20, dates: long_ago }] }] },
        { rating: 4,
          experiences: [{ spans: [{ progress: 0.40, dates: long_ago }] }] },
        { rating: 8,
          experiences: [{ spans: [{ progress: 1.0, dates: long_ago }] }] },
        { rating: 16, experiences: [{ spans: [] }] },
        { rating: 32, experiences: [] },
      ],
    },
    # Test cases for "done=none" and "done!=none" are omitted because the done
    # done filter always excludes items that are not done.
    :"done (or)" => {
      input: "average rating done=20%,100%",
      result: 5,
      items: [
        { rating: 2,
          experiences: [{ spans: [{ progress: 0.20, dates: long_ago }] }] },
        { rating: 4,
          experiences: [{ spans: [{ progress: 0.40, dates: long_ago }] }] },
        { rating: 8,
          experiences: [{ spans: [{ progress: 1.0, dates: long_ago }] }] },
        { rating: 16, experiences: [] },
      ],
    },
    :"done (not)" => {
      input: "average rating done!=20%,40%",
      result: 8,
      items: [
        { rating: 2,
          experiences: [{ spans: [{ progress: 0.20, dates: long_ago }] }] },
        { rating: 4,
          experiences: [{ spans: [{ progress: 0.40, dates: long_ago }] }] },
        { rating: 8,
          experiences: [{ spans: [{ progress: 1.0, dates: long_ago }] }] },
        { rating: 16, experiences: [] },
      ],
    },
    :"done filters out non-matching experiences" => {
      input: "total amount done=20%",
      result: 20,
      items: [
        { experiences: [
            { variant_index: 0,
              spans: [{ progress: 0.20, amount: 100, dates: long_ago }] },
            { variant_index: 0,
              spans: [{ progress: 0.40, amount: 100, dates: Date.today.. }] }],
          variants: [{}] },
        { experiences: [{ spans: [] }] },
        { experiences: [] },
      ],
    },
    :"done filters out empty experiences" => {
      input: "average rating done=20%",
      result: 2,
      items: [
        { rating: 2,
          experiences: [{ spans: [
            { progress: 0.20, dates: long_ago }] }] },
        { rating: 4, experiences: [{ spans: [] }] },
        { rating: 8, experiences: [] },
      ],
    },
    :"done filters out non-matching experiences (not)" => {
      input: "total amount done!=40%",
      result: 20,
      items: [
        { experiences: [
            { variant_index: 0,
              spans: [{ progress: 0.20, amount: 100, dates: long_ago }] },
            { variant_index: 0,
              spans: [{ progress: 0.40, amount: 100, dates: Date.today.. }] }],
          variants: [{}] },
        { experiences: [] },
      ],
    },
    :"done filters out empty experiences (not)" => {
      input: "average rating done!=40%",
      result: 2,
      items: [
        { rating: 2,
          experiences: [{ spans: [
            { progress: 0.20, dates: long_ago }] }] },
        { rating: 4, experiences: [] },
      ],
    },
    :"done (greater than)" => {
      input: "average rating done>20%",
      result: 4,
      items: [
        { rating: 2,
          experiences: [{ spans: [{ progress: 0.20, dates: long_ago }] }] },
        { rating: 4,
          experiences: [{ spans: [{ progress: 1.0, dates: long_ago }] }] },
        { rating: 8, experiences: [] },
      ],
    },
    :"done (greater than or equal to)" => {
      input: "average rating done>=20%",
      result: 3,
      items: [
        { rating: 2,
          experiences: [{ spans: [{ progress: 0.20, dates: long_ago }] }] },
        { rating: 4,
          experiences: [{ spans: [{ progress: 1.0, dates: long_ago }] }] },
        { rating: 8, experiences: [] },
      ],
    },
    :"done (less than)" => {
      input: "average rating done<100%",
      result: 2,
      items: [
        { rating: 2,
          experiences: [{ spans: [{ progress: 0.20, dates: long_ago }] }] },
        { rating: 4,
          experiences: [{ spans: [{ progress: 1.0, dates: long_ago }] }] },
        { rating: 8, experiences: [] },
      ],
    },
    :"done (less than or equal to)" => {
      input: "average rating done<=100%",
      result: 3,
      items: [
        { rating: 2,
          experiences: [{ spans: [{ progress: 0.20, dates: long_ago }] }] },
        { rating: 4,
          experiences: [{ spans: [{ progress: 1.0, dates: long_ago }] }] },
        { rating: 8, experiences: [] },
      ],
    },
    :"format" => {
      input: "average rating format=print",
      result: 2,
      items: [
        { rating: 2, variants: [{ format: :print }] },
        { rating: 4, variants: [{ format: :audio }] },
        { rating: 8, variants: [] },
      ],
    },
    :"format (or, none)" => {
      input: "average rating format=print,audio,none",
      result: 22/3.0,
      items: [
        { rating: 2, variants: [{ format: :print }] },
        { rating: 4, variants: [{ format: :audio }, { format: :ebook }] },
        { rating: 8, variants: [{ format: :clay_tablet }] },
        { rating: 16, variants: [] },
      ],
    },
    :"format (not, none)" => {
      input: "average rating format!=print,audio,none",
      result: 6,
      items: [
        { rating: 2, variants: [{ format: :print }] },
        { rating: 4, variants: [{ format: :audio }, { format: :ebook }] },
        { rating: 8, variants: [{ format: :clay_tablet }] },
        { rating: 16, variants: [] },
      ],
    },
    :"format filters out non-matching variants" => {
      input: "average length format=print",
      result: 10,
      items: [
        { variants: [
            { format: :print, length: 10 },
            { format: :audio, length: 20 }] },
      ],
    },
    :"format filters out non-matching variants (not)" => {
      input: "average length format!=print",
      result: 20,
      items: [
        { variants: [
            { format: :print, length: 10 },
            { format: :audio, length: 20 }] },
      ],
    },
    :"format filters out non-matching experiences" => {
      input: "average amount format=print",
      result: 10,
      items: [
        { variants: [
            { format: :print },
            { format: :audio }],
          experiences: [
            { variant_index: 0, spans: [{ amount: 10 }] },
            { variant_index: 1, spans: [{ amount: 20 }] }] },
      ],
    },
    :"format filters out non-matching experiences (not)" => {
      input: "average amount format!=print",
      result: 20,
      items: [
        { variants: [
            { format: :print },
            { format: :audio }],
          experiences: [
            { variant_index: 0, spans: [{ amount: 10 }] },
            { variant_index: 1, spans: [{ amount: 20 }] }] },
      ],
    },
    :"author" => {
      input: "average rating author=jrr tolkien",
      result: 2,
      items: [
        { rating: 2, author: "J. R. R. Tolkien" },
        { rating: 4, author: "Christopher Tolkien" },
        { rating: 8, author: nil },
      ],
    },
    :"author (or, none)" => {
      input: "average rating author=jrr tolkien,christopher tolkien,none",
      result: 22/3.0,
      items: [
        { rating: 2, author: "J. R. R. Tolkien" },
        { rating: 4, author: "Christopher Tolkien" },
        { rating: 8, author: "some rando" },
        { rating: 16, author: nil },
      ],
    },
    :"author (not, none)" => {
      input: "average rating author!=jrr tolkien,none",
      result: 4,
      items: [
        { rating: 2, author: "J. R. R. Tolkien" },
        { rating: 4, author: "Christopher Tolkien" },
        { rating: 8, author: nil },
      ],
    },
    :"author (includes, none)" => {
      input: "average rating author~tolkien,none",
      result: 22/3.0,
      items: [
        { rating: 2, author: "J. R. R. Tolkien" },
        { rating: 4, author: "Christopher Tolkien" },
        { rating: 8, author: "some rando" },
        { rating: 16, author: nil },
      ],
    },
    :"author (excludes, none)" => {
      input: "average rating author!~jrr,chris,none",
      result: 8,
      items: [
        { rating: 2, author: "J. R. R. Tolkien" },
        { rating: 4, author: "Christopher Tolkien" },
        { rating: 8, author: "some rando" },
        { rating: 16, author: nil },
      ],
    },
    :"title" => {
      input: "average rating title=hello mr. smith: the life of a secret agent",
      result: 2,
      items: [
        { rating: 2, title: "Hello, Mr. Smith: The Life of a Secret Agent" },
        { rating: 4, title: "Mr. Smith Returns" },
        { rating: 8, title: "" },
      ],
    },
    :"title ('the', 'a', and non-alphabetic omitted)" => {
      input: "average rating title=hello mrsmith life of secretagent",
      result: 2,
      items: [
        { rating: 2, title: "Hello, Mr. Smith: The Life of a Secret Agent" },
        { rating: 4, title: "Mr. Smith Returns" },
        { rating: 8, title: "" },
      ],
    },
    # Test cases for "title=none" and "title!=none" are omitted because a title
    # is always required.
    :"title (or)" => {
      input: "average rating title=mr smith returns, hello mr. smith: the life of a secret agent",
      result: 3,
      items: [
        { rating: 2, title: "Hello, Mr. Smith: The Life of a Secret Agent" },
        { rating: 4, title: "Mr. Smith Returns" },
        { rating: 8, title: "" },
      ],
    },
    :"title (includes)" => {
      input: "average rating title~mr smith",
      result: 3,
      items: [
        { rating: 2, title: "Hello, Mr. Smith: The Life of a Secret Agent" },
        { rating: 4, title: "Mr. Smith Returns" },
        { rating: 8, title: "" },
      ],
    },
    :"title (excludes)" => {
      input: "average rating title!~hello,return",
      result: 8,
      items: [
        { rating: 2, title: "Hello, Mr. Smith: The Life of a Secret Agent" },
        { rating: 4, title: "Mr. Smith Returns" },
        { rating: 8, title: "" },
      ],
    },
    :"series" => {
      input: "average rating series=goose bumps begin",
      result: 2,
      items: [
        { rating: 2, variants: [
            { series: [{ name: "Goosebumps Begin", volume: 1 }] }] },
        { rating: 4, variants: [
            { series: [{ name: "Goosebumps Return", volume: 10 }] }] },
        { rating: 8, variants: [] },
      ],
    },
    :"series (or, none)" => {
      input: "average rating series=goose bumps begin,goose bumps return,none",
      result: 54/4.0,
      items: [
        { rating: 2, variants: [
            { series: [{ name: "Goosebumps Begin", volume: 1 }] }] },
        { rating: 4, variants: [
            { series: [{ name: "Goosebumps Return", volume: 10 }] },
            { series: [{ name: "The Last Goosebumps", volume: 2 }] }] },
        { rating: 8, variants: [
            { series: [{ name: "The Last Goosebumps", volume: 1 }] }] },
        { rating: 16, variants: [{ series: [] }] },
        { rating: 32, variants: [] },
      ],
    },
    :"series (not, none)" => {
      input: "average rating series!=goosebumps begin,goosebumps return,none",
      result: 8,
      items: [
        { rating: 2, variants: [
            { series: [{ name: "Goosebumps Begin", volume: 1 }] },
            { series: [{ name: "Goosebumps Return", volume: 4 }] }] },
        { rating: 4, variants: [
            { series: [{ name: "Goosebumps Return", volume: 10 }] }] },
        { rating: 8, variants: [
            { series: [{ name: "The Last Goosebumps", volume: 5 }] },
            { series: [{ name: "Goosebumps Return", volume: 4 }] }] },
        { rating: 16, variants: [{ series: [] }] },
        { rating: 32, variants: [] },
      ],
    },
    :"series (includes, none)" => {
      input: "average rating series~begin,return,none",
      result: 54/4.0,
      items: [
        { rating: 2, variants: [
            { series: [{ name: "Goosebumps Begin", volume: 1 }] }] },
        { rating: 4, variants: [
            { series: [{ name: "Goosebumps Return", volume: 10 }] },
            { series: [{ name: "The Last Goosebumps", volume: 2 }] }] },
        { rating: 8, variants: [
            { series: [{ name: "The Last Goosebumps", volume: 1 }] }] },
        { rating: 16, variants: [{ series: [] }] },
        { rating: 32, variants: [] },
      ],
    },
    :"series (excludes, none)" => {
      input: "average rating series!~begin,return,none",
      result: 8,
      items: [
        { rating: 2, variants: [
            { series: [{ name: "Goosebumps Begin", volume: 1 }] },
            { series: [{ name: "Goosebumps Return", volume: 4 }] }] },
        { rating: 4, variants: [
            { series: [{ name: "Goosebumps Return", volume: 10 }] }] },
        { rating: 8, variants: [
            { series: [{ name: "The Last Goosebumps", volume: 5 }] },
            { series: [{ name: "Goosebumps Return", volume: 4 }] }] },
        { rating: 16, variants: [{ series: [] }] },
        { rating: 32, variants: [] },
      ],
    },
    :"series filters out non-matching variants" => {
      input: "average length series=goosebumps begin",
      result: 10,
      items: [
        { variants: [
            { length: 10, series: [{ name: "Goosebumps Begin", volume: 1 }] },
            { length: 20, series: [{ name: "Goosebumps Return", volume: 10 }] }] },
      ],
    },
    :"series filters out non-matching variants (not)" => {
      input: "average length series!=goosebumps begin",
      result: 20,
      items: [
        { variants: [
            { length: 10, series: [{ name: "Goosebumps Begin", volume: 1 }] },
            { length: 20, series: [{ name: "Goosebumps Return", volume: 10 }] }] },
      ],
    },
    :"series filters out non-matching experiences" => {
      input: "average amount series=goosebumps begin",
      result: 10,
      items: [
        { variants: [
            { series: [{ name: "Goosebumps Begin", volume: 1 }] },
            { series: [{ name: "Goosebumps Return", volume: 10 }] }],
          experiences: [
            { variant_index: 0, spans: [{ amount: 10 }] },
            { variant_index: 1, spans: [{ amount: 20 }] }] },
      ],
    },
    :"series filters out non-matching experiences (not)" => {
      input: "average amount series!=goosebumps begin",
      result: 20,
      items: [
        { variants: [
            { series: [{ name: "Goosebumps Begin", volume: 1 }] },
            { series: [{ name: "Goosebumps Return", volume: 10 }] }],
          experiences: [
            { variant_index: 0, spans: [{ amount: 10 }] },
            { variant_index: 1, spans: [{ amount: 20 }] }] },
      ],
    },
    :"source" => {
      input: "average rating source=little library",
      result: 2,
      items: [
        { rating: 2, variants: [
            { sources: [{ name: "Little Library", url: nil }] }] },
        { rating: 4, variants: [
            { sources: [{ name: nil, url: "https://archive.org" }] }] },
        { rating: 8, variants: [] },
      ],
    },
    :"source (or, none)" => {
      input: "average rating source=little library,https://archive.org, none",
      result: 54/4.0,
      items: [
        { rating: 2, variants: [
            { sources: [
                { name: "Little Library", url: nil },
                { name: nil, url: "https://archive.org" }] }] },
        { rating: 4, variants: [
            { sources: [{ name: nil, url: "https://archive.org" }] }] },
        { rating: 8, variants: [
            { sources: [{ name: nil, url: "https://home.com" }] }] },
        { rating: 16, variants: [{ sources: [] }] },
        { rating: 32, variants: [] },
      ],
    },
    :"source (not, none)" => {
      input: "average rating source!=little library,https://archive.org, none",
      result: 8,
      items: [
        { rating: 2, variants: [
            { sources: [{ name: "Little Library", url: nil }] }] },
        { rating: 4, variants: [
            { sources: [{ name: nil, url: "https://archive.org" }] }] },
        { rating: 8, variants: [
            { sources: [{ name: nil, url: "https://home.com" }] }] },
        { rating: 16, variants: [{ sources: [] }] },
        { rating: 32, variants: [] },
      ],
    },
    :"source (includes, none)" => {
      input: "average rating source~library,archive,none",
      result: 54/4.0,
      items: [
        { rating: 2, variants: [
            { sources: [
                { name: "Little Library", url: nil },
                { name: nil, url: "https://archive.org" }] }] },
        { rating: 4, variants: [
            { sources: [{ name: nil, url: "https://archive.org" }] }] },
        { rating: 8, variants: [
            { sources: [{ name: nil, url: "https://home.com" }] }] },
        { rating: 16, variants: [{ sources: [] }] },
        { rating: 32, variants: [] },
      ],
    },
    :"source (excludes, none)" => {
      input: "average rating source!~library,archive,none",
      result: 8,
      items: [
        { rating: 2, variants: [
            { sources: [
                { name: "Little Library", url: nil },
                { name: nil, url: "https://archive.org" }] }] },
        { rating: 4, variants: [
            { sources: [{ name: nil, url: "https://archive.org" }] }] },
        { rating: 8, variants: [
            { sources: [{ name: nil, url: "https://home.com" }] }] },
        { rating: 16, variants: [{ sources: [] }] },
        { rating: 32, variants: [] },
      ],
    },
    :"source filters out non-matching variants" => {
      input: "average length source=little library",
      result: 10,
      items: [
        { variants: [
            { length: 10, sources: [{ name: "Little Library", url: nil }] },
            { length: 20, sources: [{ name: nil, url: "https://archive.org" }] }] },
      ],
    },
    :"source filters out non-matching variants (not)" => {
      input: "average length source!=little library",
      result: 20,
      items: [
        { variants: [
            { length: 10, sources: [{ name: "Little Library", url: nil }] },
            { length: 20, sources: [{ name: nil, url: "https://archive.org" }] }] },
      ],
    },
    :"source filters out non-matching experiences" => {
      input: "average length source=little library",
      result: 10,
      items: [
        { variants: [
            { length: 10, sources: [{ name: "Little Library", url: nil }] },
            { length: 20, sources: [{ name: nil, url: "https://archive.org" }] }],
          experiences: [
            { variant_index: 0, spans: [{ amount: 10 }] },
            { variant_index: 1, spans: [{ amount: 20 }] }] },
      ],
    },
    :"source filters out non-matching experiences (not)" => {
      input: "average length source!=little library",
      result: 20,
      items: [
        { variants: [
            { length: 10, sources: [{ name: "Little Library", url: nil }] },
            { length: 20, sources: [{ name: nil, url: "https://archive.org" }] }],
          experiences: [
            { variant_index: 0, spans: [{ amount: 10 }] },
            { variant_index: 1, spans: [{ amount: 20 }] }] },
      ],
    },
    :"end date" => {
      input: "average rating end-date=2022/10",
      result: 4,
      items: [
        { rating: 4, experiences: [{ spans: [
            { dates: Date.new(2022, 9, 1)..Date.new(2022, 10, 1) }] }] },
        { rating: 8, experiences: [{ spans: [
            { dates: Date.new(2022, 9, 1)..Date.new(2022, 11, 1) }] }] },
        { rating: 16, experiences: [{ spans: [] }] },
        { rating: 32, experiences: [] }
      ],
    },
    :"end date (year only)" => {
      input: "average rating end-date=2022",
      result: 6,
      items: [
        { rating: 2, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2021, 12, 31) }] }] },
        { rating: 4, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2022, 1, 1) }] }] },
        { rating: 8, experiences: [{ spans: [
            { dates: Date.new(2022, 12, 1)..Date.new(2022, 12, 31) }] }] },
        { rating: 16, experiences: [{ spans: [
            { dates: Date.new(2022, 12, 1)..Date.new(2023, 1, 1) }] }] },
      ],
    },
    :"end date (range)" => {
      input: "average rating end-date=2022/10-2022/11",
      result: 3,
      items: [
        { rating: 2, experiences: [{ spans: [
            { dates: Date.new(2022, 9, 1)..Date.new(2022, 10, 1) }] }] },
        { rating: 4, experiences: [{ spans: [
            { dates: Date.new(2022, 9, 1)..Date.new(2022, 11, 30) }] }] },
        { rating: 8, experiences: [{ spans: [
            { dates: Date.new(2022, 9, 1)..Date.new(2022, 12, 1) }] }] },
        { rating: 16, experiences: [{ spans: [] }] },
        { rating: 32, experiences: [] }
      ],
    },
    :"end date (range without end year)" => {
      input: "average rating end-date=2022/10-11",
      result: 6,
      items: [
        { rating: 2, experiences: [{ spans: [
            { dates: Date.new(2022, 9, 1)..Date.new(2022, 9, 30) }] }] },
        { rating: 4, experiences: [{ spans: [
            { dates: Date.new(2022, 9, 1)..Date.new(2022, 10, 1) }] }] },
        { rating: 8, experiences: [{ spans: [
            { dates: Date.new(2022, 9, 1)..Date.new(2022, 11, 30) }] }] },
        { rating: 16, experiences: [{ spans: [
            { dates: Date.new(2022, 9, 1)..Date.new(2022, 12, 1) }] }] },
      ],
    },
    :"end date (range without start month)" => {
      input: "average rating end-date=2022-2022/11",
      result: 6,
      items: [
        { rating: 2, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2021, 12, 31) }] }] },
        { rating: 4, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2022, 1, 1) }] }] },
        { rating: 8, experiences: [{ spans: [
            { dates: Date.new(2022, 9, 1)..Date.new(2022, 11, 30) }] }] },
        { rating: 16, experiences: [{ spans: [
            { dates: Date.new(2022, 9, 1)..Date.new(2022, 12, 1) }] }] },
      ],
    },
    :"end date (range without either month)" => {
      input: "average rating end-date=2022-2023",
      result: 6,
      items: [
        { rating: 2, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2021, 12, 31) }] }] },
        { rating: 4, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2022, 1, 1) }] }] },
        { rating: 8, experiences: [{ spans: [
            { dates: Date.new(2023, 12, 1)..Date.new(2023, 12, 31) }] }] },
        { rating: 16, experiences: [{ spans: [
            { dates: Date.new(2023, 12, 1)..Date.new(2024, 1, 1) }] }] },
      ],
    },
    :"end date (less than)" => {
      input: "average rating end-date<2022",
      result: 2,
      items: [
        { rating: 2, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2021, 12, 31) }] }] },
        { rating: 4, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2022, 1, 1) }] }] },
        { rating: 8, experiences: [{ spans: [
            { dates: Date.new(2022, 12, 1)..Date.new(2022, 12, 31) }] }] },
        { rating: 16, experiences: [{ spans: [
            { dates: Date.new(2022, 12, 1)..Date.new(2023, 1, 1) }] }] },
      ],
    },
    :"end date (less than or equal to)" => {
      input: "average rating end-date<=2022",
      result: 14/3.0,
      items: [
        { rating: 2, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2021, 12, 31) }] }] },
        { rating: 4, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2022, 1, 1) }] }] },
        { rating: 8, experiences: [{ spans: [
            { dates: Date.new(2022, 12, 1)..Date.new(2022, 12, 31) }] }] },
        { rating: 16, experiences: [{ spans: [
            { dates: Date.new(2022, 12, 1)..Date.new(2023, 1, 1) }] }] },
      ],
    },
    :"end date (greater than)" => {
      input: "average rating end-date>2022",
      result: 16,
      items: [
        { rating: 2, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2021, 12, 31) }] }] },
        { rating: 4, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2022, 1, 1) }] }] },
        { rating: 8, experiences: [{ spans: [
            { dates: Date.new(2022, 12, 1)..Date.new(2022, 12, 31) }] }] },
        { rating: 16, experiences: [{ spans: [
            { dates: Date.new(2022, 12, 1)..Date.new(2023, 1, 1) }] }] },
      ],
    },
    :"end date (greater than or equal to)" => {
      input: "average rating end-date>=2022",
      result: 28/3.0,
      items: [
        { rating: 2, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2021, 12, 31) }] }] },
        { rating: 4, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2022, 1, 1) }] }] },
        { rating: 8, experiences: [{ spans: [
            { dates: Date.new(2022, 12, 1)..Date.new(2022, 12, 31) }] }] },
        { rating: 16, experiences: [{ spans: [
            { dates: Date.new(2022, 12, 1)..Date.new(2023, 1, 1) }] }] },
      ],
    },
    :"end date (not)" => {
      input: "average rating end-date!=2022, 2021",
      result: 16,
      items: [
        { rating: 2, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2021, 12, 31) }] }] },
        { rating: 4, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2022, 1, 1) }] }] },
        { rating: 8, experiences: [{ spans: [
            { dates: Date.new(2022, 12, 1)..Date.new(2022, 12, 31) }] }] },
        { rating: 16, experiences: [{ spans: [
            { dates: Date.new(2022, 12, 1)..Date.new(2023, 1, 1) }] }] },
      ],
    },
    :"end date (or)" => {
      input: "average rating end-date=2021, 2023",
      result: 9,
      items: [
        { rating: 2, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2021, 12, 31) }] }] },
        { rating: 4, experiences: [{ spans: [
            { dates: Date.new(2021, 12, 1)..Date.new(2022, 1, 1) }] }] },
        { rating: 8, experiences: [{ spans: [
            { dates: Date.new(2022, 12, 1)..Date.new(2022, 12, 31) }] }] },
        { rating: 16, experiences: [{ spans: [
            { dates: Date.new(2022, 12, 1)..Date.new(2023, 1, 1) }] }] },
      ],
    },
    :"end date filters out non-matching experiences" => {
      input: "average amount end-date=2022",
      result: 10,
      items: [
        { rating: 2,
          experiences: [
            { variant_index: 0,
              spans: [{ amount: 10, dates: Date.new(2021, 12, 1)..Date.new(2022, 1, 1) }] },
            { variant_index: 0,
              spans: [{ amount: 20, dates: Date.new(2022, 12, 1)..Date.new(2023, 1, 1) }] }],
          variants: [{}] },
      ],
    },
    :"end date filters out non-matching variants" => {
      input: "average length end-date=2022",
      result: 10,
      items: [
        { rating: 2,
          experiences: [
            { variant_index: 0,
              spans: [{ dates: Date.new(2021, 12, 1)..Date.new(2022, 1, 1) }] },
            { variant_index: 1,
              spans: [{ dates: Date.new(2022, 12, 1)..Date.new(2023, 1, 1) }] }],
          variants: [
            { length: 10 },
            { length: 20 },
        ]},
      ],
    },
    :"date" => {
      input: "total amount date=2022/9",
      result: 100,
      items: [
        # before
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 50,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 1)..Date.new(2022, 8, 31) }] }] },
        # before, during, and after
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 300,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 2)..Date.new(2022, 10, 30) }] }] },
        # after
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 1000,
                  progress: 1.0,
                  dates: Date.new(2022, 10, 1)..Date.new(2022, 10, 31) }] }] },
        { experiences: [] },
      ],
    },
    :"date (with final endless date range)" => {
      input: "total amount date=2022/9",
      result: 150,
      items: [
        # before
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 50,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 1)..Date.new(2022, 8, 31) }] }] },
        # before, during, and after
        { title: "boop",
          variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 300,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 3).. }] }] },
        # after
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 1000,
                  progress: 1.0,
                  dates: Date.new(2022, 10, 1)..Date.new(2022, 10, 31) }] }] },
        { experiences: [] },
      ],
    },
    :"date (or)" => {
      input: "total amount date=2022/10, 2022/8",
      result: 1250,
      items: [
        # before
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 50,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 1)..Date.new(2022, 8, 31) }] }] },
        # before, during, and after
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 300,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 2)..Date.new(2022, 10, 30) }] }] },
        # after
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 1000,
                  progress: 1.0,
                  dates: Date.new(2022, 10, 1)..Date.new(2022, 10, 31) }] }] },
        { experiences: [] },
      ],
    },
    :"date (not)" => {
      input: "total amount date!=2022/9, 2022/11",
      result: 750,
      items: [
        # before
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 50,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 1)..Date.new(2022, 8, 31) }] }] },
        # before, during, and after
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 300,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 2)..Date.new(2022, 10, 30) }] }] },
        # after
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 1000,
                  progress: 1.0,
                  dates: Date.new(2022, 10, 2)..Date.new(2022, 11, 30) }] }] },
        { experiences: [] },
      ],
    },
    :"date (greater than)" => {
      input: "total amount date>2022/9",
      result: 1100,
      items: [
        # before
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 50,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 1)..Date.new(2022, 8, 31) }] }] },
        # before, during, and after
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 300,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 2)..Date.new(2022, 10, 30) }] }] },
        # after
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 1000,
                  progress: 1.0,
                  dates: Date.new(2022, 10, 1)..Date.new(2022, 10, 31) }] }] },
        { experiences: [] },
      ],
    },
    :"date (greater than or equal to)" => {
      input: "total amount date>=2022/9",
      result: 1200,
      items: [
        # before
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 50,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 1)..Date.new(2022, 8, 31) }] }] },
        # before, during, and after
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 300,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 2)..Date.new(2022, 10, 30) }] }] },
        # after
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 1000,
                  progress: 1.0,
                  dates: Date.new(2022, 10, 1)..Date.new(2022, 10, 31) }] }] },
        { experiences: [] },
      ],
    },
    :"date (less than)" => {
      input: "total amount date<2022/9",
      result: 150,
      items: [
        # before
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 50,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 1)..Date.new(2022, 8, 31) }] }] },
        # before, during, and after
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 300,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 2)..Date.new(2022, 10, 30) }] }] },
        # after
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 1000,
                  progress: 1.0,
                  dates: Date.new(2022, 10, 1)..Date.new(2022, 10, 31) }] }] },
        { experiences: [] },
      ],
    },
    :"date (less than or equal to)" => {
      input: "total amount date<=2022/9",
      result: 250,
      items: [
        # before
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 50,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 1)..Date.new(2022, 8, 31) }] }] },
        # before, during, and after
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 300,
                  progress: 1.0,
                  dates: Date.new(2022, 8, 2)..Date.new(2022, 10, 30) }] }] },
        # after
        { variants: [{}],
          experiences: [
            { variant_index: 0,
              spans: [
                { amount: 1000,
                  progress: 1.0,
                  dates: Date.new(2022, 10, 1)..Date.new(2022, 10, 31) }] }] },
        { experiences: [] },
      ],
    },
    :"experiences" => {
      input: "average rating experience=2",
      result: 4,
      items: [
        { rating: 2, experiences: [{}, {}, {}] },
        { rating: 4, experiences: [{}, {}] },
        { rating: 8, experiences: [{}] },
        { rating: 16, experiences: [] }
      ],
    },
    :"experiences (or)" => {
      input: "average rating experience=2,3",
      result: 3,
      items: [
        { rating: 2, experiences: [{}, {}, {}] },
        { rating: 4, experiences: [{}, {}] },
        { rating: 8, experiences: [{}] },
        { rating: 16, experiences: [] }
      ],
    },
    :"experiences (not)" => {
      input: "average rating experience!=2,3",
      result: 12,
      items: [
        { rating: 2, experiences: [{}, {}, {}] },
        { rating: 4, experiences: [{}, {}] },
        { rating: 8, experiences: [{}] },
        { rating: 16, experiences: [] }
      ],
    },
    :"experiences (greater than)" => {
      input: "average rating experience>1",
      result: 3,
      items: [
        { rating: 2, experiences: [{}, {}, {}] },
        { rating: 4, experiences: [{}, {}] },
        { rating: 8, experiences: [{}] },
        { rating: 16, experiences: [] }
      ],
    },
    :"experiences (greater than or equal to)" => {
      input: "average rating experience>=2",
      result: 3,
      items: [
        { rating: 2, experiences: [{}, {}, {}] },
        { rating: 4, experiences: [{}, {}] },
        { rating: 8, experiences: [{}] },
        { rating: 16, experiences: [] }
      ],
    },
    :"experiences (less than)" => {
      input: "average rating experience<2",
      result: 12,
      items: [
        { rating: 2, experiences: [{}, {}, {}] },
        { rating: 4, experiences: [{}, {}] },
        { rating: 8, experiences: [{}] },
        { rating: 16, experiences: [] }
      ],
    },
    :"experiences (less than or equal to)" => {
      input: "average rating experience<=1",
      result: 12,
      items: [
        { rating: 2, experiences: [{}, {}, {}] },
        { rating: 4, experiences: [{}, {}] },
        { rating: 8, experiences: [{}] },
        { rating: 16, experiences: [] }
      ],
    },
    :"status" => {
      input: "average rating status=in progress",
      result: 2,
      items: [
        { rating: 2, experiences: [{ spans: [{ dates: Date.today.. }] }] },
        { rating: 4, experiences: [{ spans: [{ dates: long_ago }] }] },
        { rating: 8, experiences: [] }
      ],
    },
    # Test cases for "status=none" and "status!=none" are omitted because a
    # status is never nil.
    :"status (or)" => {
      input: "average rating status=done,planned",
      result: 6,
      items: [
        { rating: 2, experiences: [{ spans: [{ dates: Date.today.. }] }] },
        { rating: 4, experiences: [{ spans: [{ dates: long_ago }] }] },
        { rating: 8, experiences: [] }
      ],
    },
    :"status (not)" => {
      input: "average rating status!=planned,done",
      result: 2,
      items: [
        { rating: 2, experiences: [{ spans: [{ dates: Date.today.. }] }] },
        { rating: 4, experiences: [{ spans: [{ dates: long_ago }] }] },
        { rating: 8, experiences: [] }
      ],
    },
    :"status filters out non-matching experiences" => {
      input: "total amount status=in progress",
      result: 100,
      items: [
        { experiences: [
            { variant_index: 0,
              spans: [{ dates: Date.today.., amount: 100, progress: 1.0 }] },
            { variant_index: 0,
              spans: [{ dates: long_ago, amount: 150, progress: 1.0 }] }],
          variants: [{}] },
      ],
    },
    :"status filters out non-matching experiences (not)" => {
      input: "total amount status!=done",
      result: 100,
      items: [
        { experiences: [
          { variant_index: 0,
            spans: [{ dates: Date.today.., amount: 100, progress: 1.0 }] },
          { variant_index: 0,
            spans: [{ dates: long_ago, amount: 150, progress: 1.0 }] }],
        variants: [{}] },
      ],
    },
    :"genre" => {
      input: "average rating genre=history",
      result: 4,
      items: [
        { rating: 2, genres: ["fiction"] },
        { rating: 4, genres: ["history"] },
        { rating: 8, genres: [] },
      ],
    },
    :"genre (not)" => {
      input: "average rating genre!=history,fiction,none",
      result: 8,
      items: [
        { rating: 2, genres: ["fiction"] },
        { rating: 4, genres: ["history", "biography"] },
        { rating: 8, genres: ["cats"] },
        { rating: 16, genres: [] },
      ],
    },
    :"genre (none)" => {
      input: "average rating genre=none",
      result: 8,
      items: [
        { rating: 2, genres: ["fiction"] },
        { rating: 4, genres: ["history"] },
        { rating: 8, genres: [] },
      ],
    },
    :"genre (not none)" => {
      input: "average rating genre!=none",
      result: 3,
      items: [
        { rating: 2, genres: ["fiction"] },
        { rating: 4, genres: ["history"] },
        { rating: 8, genres: [] },
      ],
    },
    :"genre (or)" => {
      input: "average rating genre=history,fiction",
      result: 3,
      items: [
        { rating: 2, genres: ["fiction"] },
        { rating: 4, genres: ["history"] },
        { rating: 8, genres: [] },
      ],
    },
    :"genre (and)" => {
      input: "average rating genre=history+fiction",
      result: 2,
      items: [
        { rating: 2, genres: ["fiction", "history"] },
        { rating: 4, genres: ["history"] },
        { rating: 8, genres: [] },
      ],
    },
    :"genre (alt. and)" => {
      input: "average rating genre=history genre=fiction",
      result: 2,
      items: [
        { rating: 2, genres: ["fiction", "history"] },
        { rating: 4, genres: ["history"] },
        { rating: 8, genres: [] },
      ],
    },
    :"genre (or, and)" => {
      input: "average rating genre=science,history+fiction",
      result: 3,
      items: [
        { rating: 2, genres: ["science"] },
        { rating: 4, genres: ["fiction", "history"] },
        { rating: 8, genres: ["history"] },
        { rating: 16, genres: [] },
      ],
    },
    :"length" => {
      input: "average rating length=20",
      result: 2,
      items: [
        { rating: 2, variants: [{ length: 20 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: 8, variants: [] },
      ],
    },
    :"length (time)" => {
      input: "average rating length=1:00",
      result: 2,
      items: [
        { rating: 2, variants: [{ length: 35 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: 8, variants: [] },
      ],
    },
    :"length (or, none)" => {
      input: "average rating length=20,40,none",
      result: 22/3.0,
      items: [
        { rating: 2, variants: [{ length: 20 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: 8, variants: [{ length: 80 }] },
        { rating: 16, variants: [] },
      ],
    },
    :"length (not, none)" => {
      input: "average rating length!=20,40,none",
      result: 6,
      items: [
        { rating: 2, variants: [{ length: 20 }] },
        { rating: 4, variants: [{ length: 40 }, { length: 50 }] },
        { rating: 8, variants: [{ length: 80 }] },
        { rating: 16, variants: [] },
      ],
    },
    :"length (greater than)" => {
      input: "average rating length>20",
      result: 6,
      items: [
        { rating: 2, variants: [{ length: 20 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: 8, variants: [{ length: 100 }] },
        { rating: 16, variants: [] },
      ],
    },
    :"length (greater than or equal to)" => {
      input: "average rating length>=100",
      result: 8,
      items: [
        { rating: 2, variants: [{ length: 20 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: 8, variants: [{ length: 100 }] },
        { rating: 16, variants: [] },
      ],
    },
    :"length (less than)" => {
      input: "average rating length<40",
      result: 2,
      items: [
        { rating: 2, variants: [{ length: 20 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: 8, variants: [{ length: 100 }] },
        { rating: 16, variants: [] },
      ],
    },
    :"length (less than or equal to)" => {
      input: "average rating length<=40",
      result: 3,
      items: [
        { rating: 2, variants: [{ length: 20 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: 8, variants: [{ length: 100 }] },
        { rating: 16, variants: [] },
      ],
    },
    :"length (greater than 20, less than 100)" => {
      input: "average rating length>20 length<100",
      result: 4,
      items: [
        { rating: 2, variants: [{ length: 20 }] },
        { rating: 4, variants: [{ length: 40 }] },
        { rating: 8, variants: [{ length: 100 }] },
        { rating: 16, variants: [] },
      ],
    },
    :"note" => {
      input: "average rating note=must reread",
      result: 2,
      items: [
        { rating: 2, notes: ["Intriguing, not bad.", "Must re-read."] },
        { rating: 4, notes: ["Will re-read"] },
        { rating: 8, notes: [] },
      ],
    },
    :"note (or, include, none)" => {
      input: "average rating note~not bad, will, none",
      result: 22/3.0,
      items: [
        { rating: 2, notes: ["Intriguing, not bad.", "Must re-read."] },
        { rating: 4, notes: ["Will re-read"] },
        { rating: 8, notes: ["Definitely a favorite."] },
        { rating: 16, notes: [] },
      ],
    },
    :"note (exclude, none)" => {
      input: "average rating note!~not bad,reread,none",
      result: 8,
      items: [
        { rating: 2, notes: ["Intriguing, not bad.", "Must re-read."] },
        { rating: 4, notes: ["Will re-read"] },
        { rating: 8, notes: ["Definitely a favorite."] },
        { rating: 16, notes: [] },
      ],
    },
  }



  ## QUERIES: GROUPINGS
  # Simple queries testing each grouping.
  @queries[:groupings] = {
    :"with filter (no results)" => {
      input: "average length by rating status=in progress",
      plural_input: "average lengths by rating status=in progress",
      result: {},
      items: [
        { rating: 1, variants: [{ length: 50 }] },
      ],
    },
    :"with filter" => {
      input: "average length by rating status=planned",
      plural_input: "average lengths by rating status=planned",
      result: { 1 => 50, 2 => nil, 3 => 40 },
      items: [
        { rating: 3, variants: [{ length: 70 }] },
        { rating: 1, variants: [{ length: 50 }] },
        { rating: 3, variants: [{ length: 20 }, { length: 30 }] },
        { rating: 2, variants: [] },
      ],
    },
    rating: {
      input: "average length by rating",
      result: { 1 => 50, 2 => nil, 3 => 40 },
      items: [
        { rating: 3, variants: [{ length: 70 }] },
        { rating: 1, variants: [{ length: 50 }] },
        { rating: 3, variants: [{ length: 20 }, { length: 30 }] },
        { rating: 2, variants: [] },
        { rating: nil, variants: [] },
      ],
    },
    format: {
      input: "average length by format",
      result: { audio: 6, ebook: 16, print: 3, website: nil },
      items: [
        { variants: [{ length: 2, format: :print }, { length: 4, format: :audio }] },
        { variants: [{ length: 4, format: :print }] },
        { variants: [{ length: 8, format: :audio }] },
        { variants: [{ length: 16, format: :ebook }] },
        { variants: [{ length: nil, format: :ebook }] },
        { variants: [{ length: nil, format: :website }] },
        { variants: [] },
      ],
    },
    source: {
      input: "average length by source",
      result: { "Internet Archive" => 6, "Lexpub" => 3, "Little Library" => nil, "https://home.com" => 16 },
      items: [
        { variants: [
          { length: 2, sources: [{ name: "Lexpub", url: nil }] },
          { length: 4, sources: [{ name: "Internet Archive", url: "https://archive.org"}] }] },
        { variants: [{ length: 4, sources: [{ name: "Lexpub", url: nil }] }] },
        { variants: [{ length: 8, sources: [{ name: "Internet Archive", url: "https://archive.org"}] }] },
        { variants: [{ length: 16, sources: [{ name: nil, url: "https://home.com"}] }] },
        { variants: [{ length: nil, sources: [{ name: nil, url: "https://home.com"}] }] },
        { variants: [{ length: nil, sources: [{ name: "Little Library"}] }] },
        { variants: [] },
      ],
    },
    year: {
      input: "average rating by year",
      result: {
        2021 => 2,
        2022 => 3,
        2023 => nil,
        2024 => 2,
      },
      items: [
        { rating: 2, variants: [{}], experiences: [
          { variant_index: 0,
            spans: [
              { amount: 10,
                dates: Date.new(2021,10,10)..Date.new(2022,1,10) }] },
          { variant_index: 0,
            spans: [
              { amount: 10,
                dates: Date.new(2024,4,10)..Date.new(2024,4,15) }] }] },
        { rating: 4, variants: [{}], experiences: [
          { variant_index: 0,
            spans: [
              { amount: 10,
                dates: Date.new(2022,12,10)..Date.new(2022,12,15) }] }] },
        { rating: 8, experiences: [] },
      ],
    },
    month: {
      input: "average rating by month",
      result: {
        [2021, 1] => nil,
        [2021, 2] => nil,
        [2021, 3] => nil,
        [2021, 4] => nil,
        [2021, 5] => nil,
        [2021, 6] => nil,
        [2021, 7] => nil,
        [2021, 8] => nil,
        [2021, 9] => nil,
        [2021, 10] => 2,
        [2021, 11] => 2,
        [2021, 12] => 3,
        [2022, 1] => 3,
        [2022, 2] => 4,
        [2022, 3] => nil,
        [2022, 4] => 2,
        [2022, 5] => nil,
        [2022, 6] => nil,
        [2022, 7] => nil,
        [2022, 8] => nil,
        [2022, 9] => nil,
        [2022, 10] => nil,
        [2022, 11] => nil,
        [2022, 12] => nil,
      },
      items: [
        { rating: 2, variants: [{}], experiences: [
          { variant_index: 0,
            spans: [
              { amount: 10,
                dates: Date.new(2021,10,10)..Date.new(2022,1,10) }] },
          { variant_index: 0,
            spans: [
              { amount: 10,
                dates: Date.new(2022,4,10)..Date.new(2022,4,15) }] }] },
        { rating: 4, variants: [{}], experiences: [
          { variant_index: 0,
            spans: [
              { amount: 10,
                dates: Date.new(2021,12,10)..Date.new(2022,2,10) }] }] },
        { rating: 8, experiences: [] },
      ],
    },
    genre: {
      input: "average rating by genre",
      result: { "cats" => 16, "fiction" => 3, "fiction, history" => 5, "memoir" => nil },
      items: [
        { rating: 5, genres: %w[fiction history] },
        { rating: 2, genres: %w[fiction] },
        { rating: 4, genres: %w[fiction] },
        { rating: 16, genres: %w[cats] },
        { rating: nil, genres: %w[cats] },
        { rating: nil, genres: %w[memoir] },
        { rating: nil, genres: [] },
      ],
    },
    length: {
      input: "average length by length",
      result: {
        0..200 => 150,
        200..400 => 350,
        400..600 => nil,
        600..1000 => nil,
        1000..2000 => nil,
        2000.. => 3500,
      },
      items: [
        { variants: [{ length: 100 }, { length: 300 }] },
        { variants: [{ length: 200 }] },
        { variants: [{ length: 400 }] },
        { variants: [{ length: 3000 }] },
        { variants: [{ length: 4000 }] },
        { variants: [{ length: nil }] },
        { variants: [] },
      ],
    },
    multiple: {
      input: "average length by rating, format",
      result: {
        1 => { print: 9, audio: 20 },
        2 => {},
        3 => { print: 90, audio: 190 },
      },
      items: [
        { rating: 3, variants: [
          { format: :print, length: 100 },
          { format: :audio, length: 200 }] },
        { rating: 1, variants: [
          { format: :print, length: 10 },
          { format: :audio, length: 20 }] },
        { rating: 3, variants: [{ format: :print, length: 80 }] },
        { rating: 1, variants: [{ format: :print, length: 8 }] },
        { rating: 3, variants: [{ format: :audio, length: 180 }] },
        { rating: 2, variants: [] },
      ],
    }
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
        { variants: [{ length: Reading.time('5:00') }],
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
        { experiences: [{ spans: [{ amount: 2, progress: 1.0 }] }] },
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
        { experiences: [{ spans: [
          { amount: Reading.time('5:00'), progress: 1.0 }] }] },
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



  ## QUERIES: ERRORS
  # Bad input that should raise an error.
  @queries[:errors] = {}

  @queries[:errors][Reading::InputError] = {
    :"nonexistent filter" =>
      "average rating lengthiness=10",
    :"inapplicable operator" =>
      "average rating genre>history",
    :"inapplicable none" =>
      "average length rating>none",
    :"non-numeric rating" =>
      "average length rating=great",
    :"non-numeric length" =>
      "average rating length=short",
    :"none value for title" =>
      "average rating title=none",
    :"none value for status" =>
      "average rating status=none",
    :"none value for done" =>
      "average rating done=none",
    :"none value for experiences" =>
      "average rating experiences=none",
    :"none value for daysago" =>
      "average rating daysago=none",
    :"overlapping end-date ranges" =>
      "average rating end-date=2022/8-9, 2022/9-10",
    :"overlapping date ranges" =>
      "average rating date=2022/8-9, 2022/9-10",
    :"duplicate grouping" =>
      "average rating by genre, year, genre",
  }

  # ==== TESTS

  # TESTS: OPERATIONS
  queries[:operations].each do |key, hash|
    define_method("test_operation_#{key}") do
      items = hash.fetch(:items).map { |item_hash|
        Reading::Item.new(
          item_hash,
          view: false,
        )
      }

      input = hash.fetch(:input)

      exp = hash.fetch(:result)
      act = Reading.stats(input:, items:)

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
          view: false,
        )
      }

      input = hash.fetch(:input)

      exp = hash.fetch(:result)
      act = Reading.stats(input:, items:)

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

  # TESTS: GROUPINGS
  queries[:groupings].each do |key, hash|
    define_method("test_grouping_#{key}") do
      items = hash.fetch(:items).map { |item_hash|
        Reading::Item.new(
          item_hash,
          view: false,
        )
      }

      input = hash.fetch(:input)

      exp = hash.fetch(:result)
      act = Reading.stats(input:, items:)

      assert_equal exp, act,
        "Unexpected result #{act} from stats query \"#{name}\""

      # Alternate input style: plural
      act = Reading.stats(input: hash[:plural_input] || "#{input}s", items:)
      assert_equal(exp, act)
    end
  end

  # TESTS: RESULT FORMATTERS
  queries[:terminal_result_formatters].each do |key, hash|
    define_method("test_result_formatter_#{key}") do
      items = hash.fetch(:items).map { |item_hash|
        Reading::Config.build(hash[:config]) if hash[:config]

        Reading::Item.new(
          item_hash,
          view: false,
        )
      }

      exp = hash.fetch(:result)
      act = Reading.stats(
        input: hash.fetch(:input),
        items:,
        result_formatters: Reading::Stats::ResultFormatters::TERMINAL,
      )

      assert_equal exp, act,
        "Unexpected result #{act} from stats query \"#{name}\""

      Reading::Config.build # reset config to default
    end
  end

  ## TESTS: ERRORS
  queries[:errors].each do |error, hash|
    hash.each do |name, input|
      define_method("test_error_#{name}") do
        if name.start_with? "OK: " # Should not raise an error.
          Reading.stats(input:, items: [])
        else
          assert_raises error, "Failed to raise #{error} for: #{name}" do
            Reading.stats(input:, items: [])
          end
        end
      end
    end
  end
end
