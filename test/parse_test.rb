$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "test_helper"

require "reading"

class ParseTest < Minitest::Test
  using Reading::Util::HashDeepMerge
  using Reading::Util::HashArrayDeepFetch
  using Reading::Util::HashToStruct

  self.class.attr_reader :inputs, :outputs, :base_config

  def inputs
    self.class.inputs
  end

  def outputs
    self.class.outputs
  end

  def base_config
    self.class.base_config
  end

  @base_config = Reading::Config.new.hash

  # ==== TEST INPUT

  @inputs = {}

  ## TEST INPUT: ENABLING COLUMNS
  # In the columns tests, the input in the heredocs below are each parsed with
  # only the columns enabled that are listed in the hash key. This tests basic
  # functionality of each column, and a few possible combinations of columns.
  @inputs[:enabled_columns] = {}
  @inputs[:enabled_columns][:"head"] = <<~EOM.freeze
    \\Author - Title
    Sapiens
    Goatsong
    How To
  EOM
  @inputs[:enabled_columns][:"head, end_dates"] = <<~EOM.freeze
    \\Author - Title|End dates
    Sapiens
    Goatsong|2020/5/30
    How To
  EOM
  @inputs[:enabled_columns][:"head, start_dates"] = <<~EOM.freeze
    Sapiens|2021/9/1
    Goatsong|2020/5/1
    How To
  EOM
  @inputs[:enabled_columns][:"head, start_dates, end_dates"] = <<~EOM.freeze
    Sapiens|2021/9/1
    Goatsong|2020/5/1|2020/5/30
    How To
  EOM
  @inputs[:enabled_columns][:"rating, head, start_dates, end_dates"] = <<~EOM.freeze
    |Sapiens|2021/9/1
    5|Goatsong|2020/5/1|2020/5/30
    |How To
  EOM
  # length but no sources
  @inputs[:enabled_columns][:"rating, head, start_dates, end_dates, length"] = <<~EOM.freeze
    |Sapiens|2021/9/1||15:17
    5|Goatsong|2020/5/1|2020/5/30|247
    |How To
  EOM
  # sources but no length
  @inputs[:enabled_columns][:"rating, head, sources, start_dates, end_dates"] = <<~EOM.freeze
    |Sapiens|Vail Library B00ICN066A|2021/9/1
    5|Goatsong|0312038380|2020/5/1|2020/5/30
    |How To
  EOM
  # sources and length
  @inputs[:enabled_columns][:"rating, head, sources, start_dates, end_dates, length"] = <<~EOM.freeze
    |Sapiens|Vail Library B00ICN066A|2021/9/1||15:17
    5|Goatsong|0312038380|2020/5/1|2020/5/30|247
    |How To
  EOM



  ## TEST INPUT: FEATURES OF SINGLE COLUMNS
  # In each the features tests, a single column is enabled (specified in the
  # hash key) and a bunch of possible content for that column is tested. These
  # are the columns that are more flexible and can have lots of information
  # crammed into them.
  @inputs[:features_head] =
  {
  :"author" =>
    "Tom Holt - Goatsong",
  :"series" =>
    "Tom Holt - Goatsong -- in The Walled Orchard",
  :"series with volume" =>
    "Tom Holt - Goatsong -- The Walled Orchard, #1",
  :"multiple series" =>
    "Tom Holt - Goatsong -- in Holt Historical Fiction -- The Walled Orchard, #1",
  :"extra info" =>
    "Tom Holt - Goatsong -- paperback -- 1990",
  :"extra info and series" =>
    "Tom Holt - Goatsong -- paperback -- The Walled Orchard, #1 -- 1990",
  :"format" =>
    "📕Tom Holt - Goatsong",
  :"multi items" =>
    "📕Tom Holt - Goatsong, 🔊Sapiens",
  :"multi items without a comma" =>
    "📕Tom Holt - Goatsong 🔊Sapiens",
  :"multi items with a long separator" =>
    "📕Tom Holt - Goatsong -- 🔊Sapiens",
  :"progress" =>
    "50% 📕Tom Holt - Goatsong",
  :"progress pages" =>
    "p220 📕Tom Holt - Goatsong",
  :"progress pages without p" =>
    "220 📕Tom Holt - Goatsong",
  :"progress time" =>
    "2:30 📕Tom Holt - Goatsong",
  :"dnf in head" =>
    "DNF 📕Tom Holt - Goatsong",
  :"other string in head is ignored" =>
    "maybe will DNF 📕Tom Holt - Goatsong",
  :"dnf in head with progress" =>
    "DNF 50% 📕Tom Holt - Goatsong",
  :"dnf with multi items" =>
    "DNF 📕Tom Holt - Goatsong, 🔊Sapiens",
  :"all features" =>
    "DNF 50% 📕Tom Holt - Goatsong -- paperback -- The Walled Orchard, #1 -- 1990, 🔊Sapiens"
  }

  # The Head column is enabled by default, so the strings for other single
  # columns are preceded by the Head column.
  @inputs[:features_sources] =
  {
  :"ISBN-10" =>
    "Goatsong|0312038380",
  :"ISBN-13" =>
    "Goatsong|978-0312038380",
  :"ASIN" =>
    "Goatsong|B00GVG01HE",
  :"source" =>
    "Goatsong|Little Library",
  :"URL source" =>
    "Goatsong|https://www.edlin.org/holt",
  :"URL source with a name from config" =>
    "Goatsong|https://archive.org/details/walledorchard0000holt",
  :"multiple sources must be separated with commas" =>
    "Goatsong|Little Library, https://www.edlin.org/holt, Lexpub",
  :"source with ISBN" =>
    "Goatsong|Little Library 0312038380",
  :"sources with ISBN" =>
    "Goatsong|Little Library, https://www.edlin.org/holt, Lexpub 0312038380",
  :"simple variants" =>
    "Goatsong|📕Little Library 📕Lexpub",
  :"variant with extra info" =>
    "Goatsong|📕Little Library -- paperback -- 1990 🔊Lexpub",
  :"optional long separator can be added between variants" =>
    "Goatsong|📕Little Library -- paperback -- 1990 🔊Lexpub",
  :"variant with extra info and series" =>
    "Goatsong|📕Little Library -- paperback -- The Walled Orchard, #1 -- 1990 🔊Lexpub",
  :"variant with extra info and series from Head also" =>
    "Goatsong -- in Holt's Classical Novels -- unabridged|📕Little Library -- paperback -- The Walled Orchard, #1 -- 1990 🔊Lexpub",
  :"length after sources ISBN and before extra info" =>
    "Goatsong|📕Little Library 0312038380 247 -- paperback -- 1990 🔊Lexpub 7:03",
  :"multiple sources allowed in variant" =>
    "Goatsong|📕Little Library, https://www.edlin.org/holt, Lexpub 0312038380 247 -- paperback -- 1990 🔊Lexpub 7:03",
  :"optional commas can be added within and between variants" =>
    "Goatsong|📕Little Library, https://www.edlin.org/holt, Lexpub, 0312038380, 247 -- paperback -- 1990, 🔊Lexpub 7:03",
  }

  @inputs[:features_start_dates] =
  {
  :"start date" =>
    "Sapiens|2020/09/01",
  :"start dates" =>
    "Sapiens|2020/09/01, 2021/07/15",
  :"progress" =>
    "Sapiens|50% 2020/09/01",
  :"progress pages" =>
    "Sapiens|220p 2020/09/01",
  :"progress pages without p" =>
    "Sapiens|220 2020/09/01",
  :"progress time" =>
    "Sapiens|2:30 2020/09/01",
  :"dnf default zero" =>
    "Sapiens|DNF 2020/09/01",
  :"dnf with progress" =>
    "Sapiens|DNF 50% 2020/09/01",
  :"dnf only" =>
    "Sapiens|DNF 50%",
  :"variant" =>
    "Sapiens|2020/09/01 v2",
  :"variant only" =>
    "Sapiens|v2",
  :"group" =>
    "Sapiens|2020/09/01 v2 🤝🏼 county book club",
  :"group only" =>
    "Sapiens|🤝🏼 county book club",
  :"all features" =>
    "Sapiens|DNF 50% 2020/09/01 v2, 2:30 2021/07/15",
  }

  # The compact_planned part (unlike in other :features_x) is merely semantic;
  # it has no effect in with_columns below.
  @inputs[:features_compact_planned] =
  {
  :"title only" =>
    "\\⚡A Song for Nero",
  :"with author" =>
    "\\⚡Tom Holt - A Song for Nero",
  :"with sources" =>
    "\\⚡Tom Holt - A Song for Nero @Lexpub @Hoopla",
  :"with sources in the Sources column" =>
    "\\⚡Tom Holt - A Song for Nero|Lexpub, Hoopla",
  :"with fuller Head and Sources columns" =>
    "\\⚡Tom Holt - A Song for Nero -- unabridged -- in Holt's Classical Novels|Lexpub, Hoopla B00GW4U2TM",
  :"with sources and extra info" =>
    "\\⚡Tom Holt - A Song for Nero @Lexpub @Hoopla -- unabridged -- in Holt's Classical Novels",
  :"multiple" =>
    "\\⚡Tom Holt - A Song for Nero @Lexpub @Hoopla 🔊True Grit @Lexpub",
  :"multiple with source" =>
    "\\@Lexpub: ⚡Tom Holt - A Song for Nero @Hoopla 🔊True Grit",
  :"multiple with genre" =>
    "\\HISTORICAL FICTION: ⚡Tom Holt - A Song for Nero @Lexpub @Hoopla 🔊True Grit @Lexpub",
  :"multiple with multiple genres" =>
    "\\HISTORICAL FICTION, FAVES: ⚡Tom Holt - A Song for Nero @Lexpub @Hoopla 🔊True Grit @Lexpub",
  :"multiple with genre plus source" =>
    "\\HISTORICAL FICTION @Lexpub: ⚡Tom Holt - A Song for Nero @Hoopla 🔊True Grit",
  :"duplicate sources are ignored" =>
    "\\HISTORICAL FICTION @Lexpub: ⚡Tom Holt - A Song for Nero @Hoopla @Lexpub @Hoopla 🔊True Grit @Lexpub",
  :"multiple sources at the beginning" =>
    "\\HISTORICAL FICTION @Lexpub @https://www.lexpublib.org: ⚡Tom Holt - A Song for Nero 🔊True Grit",
  :"config-defined emojis are ignored" =>
    "\\❓HISTORICAL FICTION @Lexpub:⚡💲Tom Holt - A Song for Nero ✅@Hoopla ✅🔊True Grit",
  }

  # TODO uncomment
  @inputs[:features_history] =
  {
  # :"dates and descriptions" =>
  #   "Fullstack Ruby|2021/12/6 #1 Why Ruby2JS is a Game Changer -- 12/21 #2 Componentized View Architecture FTW! -- 2022/2/22 #3 String-Based Templates vs. DSLs",
  # :"time amounts" =>
  #   "Fullstack Ruby|2021/12/6 0:35 #1 Why Ruby2JS is a Game Changer -- 12/21 0:45 #2 Componentized View Architecture FTW! -- 2022/2/22 #3 String-Based Templates vs. DSLs",
  # :"page amounts" =>
  #   "War and Peace|2021/04/28 115p -- 4/30 96p",
  # :"page amounts without p" =>
  #   "War and Peace|2021/04/28 115 -- 4/30 96",
  # :"date ranges" =>
  #   "War and Peace|2021/04/28-29 115p -- 4/30-5/1 97p",
  # :"with description, amount is for part and not per day" =>
  #   "War and Peace|2021/04/28-29 51p Vol 1 Pt 1 -- 4/30-5/3 Vol 1 Pt 2",
  # :"stopping points for amount" =>
  #   "War and Peace|2021/04/28-29 p115 -- 4/30-5/3 p211",
  # :"mixed amounts and stopping points" =>
  #   "War and Peace|2021/04/28-29 p115 -- 4/30-5/3 24p",
  # :"reread" =>
  #   "War and Peace|2021/04/28-29 p115 -- 4/30-5/3 24p - 2022/1/1-2/15 50p",
  }



  ## TEST INPUT: ALL COLUMNS
  # For interactions between columns that are not caught in the single-column
  # tests above. Also for realistic examples from the reading.csv template:
  # https://github.com/fpsvogel/reading/blob/main/doc/reading.csv
  @inputs[:all_columns] =
  {
    :"empty Sources column doesn't prevent variant from elsewhere" =>
      "|📕Sapiens||2020/09/01",
    :"default span amount is the correct length via variants" =>
      "|Goatsong|📕Little Library 0312038380 247 -- paperback -- 1990 🔊Lexpub 7:03|2020/09/01",
  }
  @inputs[:all_columns][:"realistic examples: in progress books"] = <<~EOM.freeze
    \\Rating|Format, Author, Title|Sources, ISBN/ASIN|Start dates, Progress|End dates|Genres|Length|Notes|History
    \\------ IN PROGRESS
    |🔊Sapiens: A Brief History of Humankind|Hoopla B00ICN066A|2021/09/20||history|15:17|Easy to criticize, but I like the emphasis on human happiness. -- Ch. 5: "We did not domesticate wheat. It domesticated us." -- Discussion of that point: https://www.reddit.com/r/AskHistorians/comments/2ttpn2
    5|📕Tom Holt - Goatsong|Lexpub 0312038380|2019/05/28, 2020/05/01|2019/06/13|history, fiction|247
  EOM
  # TODO uncomment
  # @inputs[:all_columns][:"realistic examples: in progress podcasts"] = <<~EOM.freeze
  #   3|🎤Flightless Bird|Spotify https://armchairexpertpod.com/flightless-bird|||podcast|0:50 each||2022/10/06..11 x23 -- ..12/14 x1/week -- 2023/3/1.. x2/week
  #   4|🎤Pete Enns & Jared Byas - The Bible for Normal People|https://peteenns.com/podcast|||religion,podcast|||2022/12/01 0:50 #2 Richard Rohr - A Contemplative Look at The Bible -- 12/9 1:30 #19 Megan DeFranza - The Bible and Intersex Believers -- 12/21 ⭐#160 The Risk of an "Errant" Bible -- 0:50 ⭐#164 Where Did Our Bible Come From? -- 2023/1/1 #5 Mike McHargue - Science and the Bible
  # EOM
  @inputs[:all_columns][:"realistic examples: done"] = <<~EOM.freeze
    \\------ DONE
    4|📕Robert Louis Stevenson - Insula Thesauraria -- in Mount Hope Classics -- trans. Arcadius Avellanus|1533694567|2020/10/20 🤝🏼Latin reading group|2021/08/31|latin, fiction|260
    2|DNF 50% 🔊Total Cat Mojo|gift from neighbor Edith B01NCYY3BV|2020/03/21|2020/04/01|cats|10:13|🔒I would've felt bad if I hadn't tried.
    1|DNF 🎤FiveThirtyEight Politics 🎤The NPR Politics Podcast 🎤Pod Save America||2021/08/02|2021/08/02|politics, podcast|0:30|Not very deep. Disappointing.
    5|Randall Munroe - What If?: Serious Scientific Answers to Absurd Hypothetical Questions|🔊Lexpub B00LV2F1ZA 6:36 -- unabridged -- published 2016 ⚡Amazon B00IYUYF4A 320 -- published 2014|2021/08/01, 2021/08/16 v2 🤝🏼with Sam, 2021/09/01|2021/08/15, 2021/08/28, 2021/09/10|science||Favorites: Global Windstorm, Relativistic Baseball, Laser Pointer, Hair Dryer, Machine-Gun Jetpack, Neutron Bullet. -- 💬It's been a long time since I gave highest marks to a "just for fun" book, but wow, this was fun. So fun that after listening to the audiobook, I immediately proceeded to read the book, for its illustrations. If I'd read this as a kid, I might have been inspired to become a scientist.
  EOM
  @inputs[:all_columns][:"realistic examples: planned"] = <<~EOM.freeze
    \\------ PLANNED
    |⚡Tom Holt - Alexander At The World's End|B00GVG00R0|||historical fiction|484
    \\
    \\⚡How to Think Like a Roman Emperor
    \\🔊Trevor Noah - Born a Crime @Lexpub @Jeffco
    \\
    \\HISTORICAL FICTION: ⚡Tom Holt - A Song for Nero 🔊True Grit @Lexpub 🔊Two Gentlemen of Lebowski @https://www.runleiarun.com/lebowski/
    \\SCIENCE, WEIRD @Lexpub: 📕Randall Munroe - How To 🔊Weird Earth @Hoopla
  EOM



  ## TEST INPUT: ERRORS
  # Bad input that should raise an error.
  @inputs[:errors] = {}
  @inputs[:errors][Reading::ParsingError] =
  {
  :"non-numeric rating" =>
    "a|Sapiens",
  :"comment containing a format emoji (matched as compact planned)" =>
    "\\Testing a row with 📕",
  :"date not in yyyy/mm/dd format" =>
    "|Sapiens||2019-01-01|2020/01/01",
  :"start date content without a date" =>
    "|Sapiens||no date here|2020/01/01",
  :"end date content without a date" =>
    "|Sapiens||2019/01/01|no date here",
  :"incomplete date is the same as no date" =>
    "|Sapiens||2019/01|2020/01/01",
  :"conjoined dates" =>
    "|Sapiens||2019/01/01 2020/01/01",
  }
  @inputs[:errors][Reading::InvalidDateError] =
  {
  :"unparsable date" =>
    "|Sapiens||2019/01/32|2020/01/01",
  :"end date before start date" =>
    "|Sapiens||2020/01/01|2019/01/01",
  :"start dates out of order" =>
    "|Sapiens||2019/01/01, 2018/01/01",
  :"end date after the next start date for the same variant" =>
    "|Sapiens||2019/01/01, 2019/02/01|2019/03/01, ",
  :"OK: end date after the next start date for different variants" =>
    "|Sapiens||2019/01/01, 2019/02/01 v2|2019/03/01, ",
  }
  @inputs[:errors][Reading::InvalidHeadError] =
  {
  :"missing Head column" =>
    "2",
  :"blank Head column" =>
    "2| |Hoopla",
  :"missing title" =>
    "|📕 ",
  :"missing title after author" =>
    "|📕Mark Twain - ",
  :"missing title in compact planned row" =>
    "\\📕",
  :"missing title after author in compact planned row" =>
    "\\📕Mark Twain - ",
  }
  @inputs[:errors][Reading::TooManyColumnsError] =
  {
  :"column beyond the number of enabled columns" =>
    "|Sapiens||||||||something",
  :"empty column beyond the number of enabled columns" =>
    "|Sapiens||||||||| ",
  :"multiple other columns in a compact planned item when only Sources is allowed" =>
    "\\⚡Tom Holt - A Song for Nero|Lexpub, Hoopla|2022/12/21",
  }
  # These are examples of missing columns that do NOT raise an error during parsing.
  # I *could* add more validations to avoid these, but for me these never happen
  # because I view my reading.csv with color-coded columns (Rainbow CSV extension
  # for VS Code). Even so, I'm documenting these odd cases here.
  @inputs[:errors][Reading::Error] =
  {
  :"OK: missing Rating column if the title is numeric (no InvalidRatingError is raised)" =>
    "1984|https://www.george-orwell.org/1984",
  :"OK: missing Head column (the date is parsed as the title)" =>
    "|2019/01/01",
  :"OK: missing Source column (the date is parsed as a source)" =>
    "|Sapiens|2019/01/01",
  :"OK: missing Genres column (the length is parsed as a genre)" =>
    "|Sapiens||2019/01/01|2020/01/01|15:17",
  :"OK: missing Notes column (History is parsed as Notes)" =>
    "|Sapiens||||history|15:17|2022/5/1 p31 -- 5/2 p54 -- 5/6-15 10p -- 5/20 p200 -- 5/21-23 done",
  }



  ## TEST INPUT: CUSTOM CONFIG
  # Bad input that should raise an error.
  @inputs[:config] = {
    :"comment_character" =>
      ["#3|Dracula",
        { comment_character: "#" }],
    :"column_separator" =>
      ["$Dracula",
        { column_separator: "$" }],
    :"column_separator can be a tab" =>
      ["\tDracula",
        { column_separator: "\t" }],
    :"skip_compact_planned" =>
      ["\\📕Dracula",
        { skip_compact_planned: true }],
    :"ignored_characters" =>
      ["|✅Dracula",
        { ignored_characters: "Da"}],
  }



  # ==== EXPECTED TEST OUTPUT
  # The results of parsing the above inputs are expected to equal the hashes below.

  def self.item_hash(**partial_hash)
    # This merge is not the same as Reading::Util::HashDeepMerge. This one uses the
    # first (empty) subhashes in the item template, for example in :variants and
    # :experiences in the item template.
    base_config.fetch(:item_template).merge(partial_hash) do |key, old_value, new_value|
      item_template_merge(key, old_value, new_value)
    end
  end

  def self.item_template_merge(key, old_value, new_value)
    if old_value.is_a?(Array) && old_value.first.is_a?(Hash)
      template = old_value.first
      new_value.map do |v|
        template.merge(v) do |k, old_v, new_v|
          item_template_merge(k, old_v, new_v)
        end
      end
    else
      new_value
    end
  end

  @outputs = {}

  @outputs[:enabled_columns] = {}
  a = item_hash(title: "Sapiens")
  b = item_hash(title: "Goatsong")
  c = item_hash(title: "How To")
  @outputs[:enabled_columns][:"head"] = [a, b, c]

  b_end_only = b.deep_merge(
    experiences: [{ spans: [{ dates: ..Date.parse("2020/5/30"),
                    progress: 1.0}] }],
  )
  @outputs[:enabled_columns][:"head, end_dates"] = [a, b_end_only, c]

  a_start = a.deep_merge(experiences: [{ spans: [{ dates: Date.parse("2021/9/1").. }] }])
  b_start = b.deep_merge(experiences: [{ spans: [{ dates: Date.parse("2020/5/1").. }] }])
  @outputs[:enabled_columns][:"head, start_dates"] = [a_start, b_start, c]

  b_end = item_hash(
    title: "Goatsong",
    experiences: [{ spans: [{ dates: Date.parse("2020/5/1")..Date.parse("2020/5/30"),
                              progress: 1.0}] }],
  )
  @outputs[:enabled_columns][:"head, start_dates, end_dates"] = [a_start, b_end, c]

  a_rating = a_start.merge(rating: nil)
  b_rating = b_end.merge(rating: 5)
  @outputs[:enabled_columns][:"rating, head, start_dates, end_dates"] = [a_rating, b_rating, c]

  a_length_and_amount = { variants: [{ length: "15:17" }],
                          experiences: [{ spans: [{ amount: "15:17" }] }] }
  b_length_and_amount = { variants: [{ length: 247 }],
                          experiences: [{ spans: [{ amount: 247 }] }] }
  a_length = a_rating.deep_merge(a_length_and_amount)
  b_length = b_rating.deep_merge(b_length_and_amount)
  @outputs[:enabled_columns][:"rating, head, start_dates, end_dates, length"] = [a_length, b_length, c]

  a_sources = a_rating.deep_merge(
    variants: [{ isbn: "B00ICN066A",
                 sources: [{ name: "Vail Library" }] }])
  b_sources = b_rating.deep_merge(variants: [{ isbn: "0312038380" }])
  @outputs[:enabled_columns][:"rating, head, sources, start_dates, end_dates"] = [a_sources, b_sources, c]

  a_many = a_sources.deep_merge(a_length_and_amount)
  b_many = b_sources.deep_merge(b_length_and_amount)
  @outputs[:enabled_columns][:"rating, head, sources, start_dates, end_dates, length"] = [a_many, b_many, c]



  @outputs[:features_head] = {}
  a = item_hash(author: "Tom Holt", title: "Goatsong")
  @outputs[:features_head][:"author"] = [a]

  series_name = "The Walled Orchard"
  series = { variants: [{ series: [{ name: series_name }] }] }
  a_series = a.deep_merge(series)
  @outputs[:features_head][:"series"] = [a_series]

  volume = { variants: [{ series: [{ volume: 1 }] }] }
  a_series_volume = a_series.deep_merge(volume)
  @outputs[:features_head][:"series with volume"] = [a_series_volume]

  multi_series = {
    variants: [{ series: [{ name: "Holt Historical Fiction", volume: nil },
                          { name: series_name, volume: 1 }] }],
  }
  a_multi_series = a.deep_merge(multi_series)
  @outputs[:features_head][:"multiple series"] = [a_multi_series]

  extra_info = { variants: [{ extra_info: %w[paperback 1990] }] }
  a_extra_info = a.deep_merge(extra_info)
  @outputs[:features_head][:"extra info"] = [a_extra_info]

  a_extra_info_series = a_extra_info.deep_merge(series).deep_merge(volume)
  @outputs[:features_head][:"extra info and series"] = [a_extra_info_series]

  format = { variants: [{ format: :print }] }
  a_format = a.deep_merge(format)
  @outputs[:features_head][:"format"] = [a_format]

  b = item_hash(title: "Sapiens", variants: [{ format: :audiobook }])
  @outputs[:features_head][:"multi items"] = [a_format, b]

  @outputs[:features_head][:"multi items without a comma"] = [a_format, b]

  @outputs[:features_head][:"multi items with a long separator"] = [a_format, b]

  progress_half = { experiences: [{ spans: [{ progress: 0.5 }] }] }
  a_progress_half = a_format.deep_merge(progress_half)
  @outputs[:features_head][:"progress"] = [a_progress_half]

  progress_pages = { experiences: [{ spans: [{ progress: 220 }] }] }
  a_progress_pages = a_format.deep_merge(progress_pages)
  @outputs[:features_head][:"progress pages"] = [a_progress_pages]

  @outputs[:features_head][:"progress pages without p"] = [a_progress_pages]

  progress_time = { experiences: [{ spans: [{ progress: "2:30" }] }] }
  a_progress_time = a_format.deep_merge(progress_time)
  @outputs[:features_head][:"progress time"] = [a_progress_time]

  progress_zero = { experiences: [{ spans: [{ progress: 0 }] }] }
  a_progress_zero = a_format.deep_merge(progress_zero)
  @outputs[:features_head][:"dnf in head"] = [a_progress_zero]

  @outputs[:features_head][:"other string in head is ignored"] = [a_format]

  @outputs[:features_head][:"dnf in head with progress"] = [a_progress_half]

  b_progress_zero = b.deep_merge(experiences: [{ spans: [{ progress: 0 }] }])
  @outputs[:features_head][:"dnf with multi items"] = [a_progress_zero, b_progress_zero]

  full_variants = extra_info.deep_merge(series).deep_merge(volume)
  a_full = a_progress_zero.deep_merge(full_variants).deep_merge(progress_half)
  b_full = b_progress_zero.deep_merge(progress_half)
  @outputs[:features_head][:"all features"] = [a_full, b_full]



  @outputs[:features_sources] = {}
  title = "Goatsong"
  a = item_hash(title:)
  isbn = "0312038380"
  a_isbn = a.deep_merge(variants: [{ isbn: isbn }])
  @outputs[:features_sources][:"ISBN-10"] = [a_isbn]

  a_isbn_13 = a.deep_merge(variants: [{ isbn: "978-0312038380" }])
  @outputs[:features_sources][:"ISBN-13"] = [a_isbn_13]

  a_asin = a.deep_merge(variants: [{ isbn: "B00GVG01HE" }])
  @outputs[:features_sources][:"ASIN"] = [a_asin]

  library = { name: "Little Library", url: nil }
  a_source = a.deep_merge(variants: [{ sources: [library] }])
  @outputs[:features_sources][:"source"] = [a_source]

  site = { name: base_config.deep_fetch(:sources, :default_name_for_url),
           url: "https://www.edlin.org/holt" }
  a_site = a.deep_merge(variants: [{ sources: [site] }])
  @outputs[:features_sources][:"URL source"] = [a_site]

  default_name = base_config.deep_fetch(:sources, :default_name_for_url)
  site_named = { name: default_name, url: "https://www.edlin.org/holt" }
  a_site_named = a.deep_merge(variants: [{ sources: [site_named] }])
  @outputs[:features_sources][:"URL source with name"] = [a_site_named]

  @outputs[:features_sources][:"URL source with name after"] = [a_site_named]

  site_auto_named = { name: "Internet Archive",
                      url: "https://archive.org/details/walledorchard0000holt" }
  a_site_auto_named = a.deep_merge(variants: [{ sources: [site_auto_named] }])
  @outputs[:features_sources][:"URL source with a name from config"] = [a_site_auto_named]

  lexpub = { name: "Lexpub", url: nil }
  three_sources = [library, site, lexpub]
  a_commas = a.deep_merge(variants: [{ sources: three_sources }])
  @outputs[:features_sources][:"multiple sources must be separated with commas"] = [a_commas]

  a_source_isbn = a.deep_merge(
    variants: [{ sources: [library],
                 isbn: isbn }],
  )
  @outputs[:features_sources][:"source with ISBN"] = [a_source_isbn]

  a_multi_sources_isbn = a.deep_merge(
    variants: [{ sources: three_sources,
                 isbn: isbn }],
  )
  @outputs[:features_sources][:"sources with ISBN"] = [a_multi_sources_isbn]

  a_variants = item_hash(
    title:,
    variants: [{ format: :print, sources: [library] },
               { format: :print, sources: [lexpub] }],
  )
  @outputs[:features_sources][:"simple variants"] = [a_variants]

  a_variant_extra_info = item_hash(
    title:,
    variants: [{ format: :print,
                 sources: [library],
                 extra_info: %w[paperback 1990] },
               { format: :audiobook,
                 sources: [lexpub] }],
  )
  @outputs[:features_sources][:"variant with extra info"] = [a_variant_extra_info]

  @outputs[:features_sources][:"optional long separator can be added between variants"] = [a_variant_extra_info]

  a_variant_series = a_variant_extra_info.deep_merge(
    variants: [{ series: [{ name: "The Walled Orchard", volume: 1 }] }],
  )
  @outputs[:features_sources][:"variant with extra info and series"] = [a_variant_series]

  a_head_extras = a_variant_extra_info.deep_merge(
    variants: [{ series: [{ name: "Holt's Classical Novels", volume: nil },
                          { name: "The Walled Orchard", volume: 1 }],
                 extra_info: %w[unabridged paperback 1990] },
               { series: [{ name: "Holt's Classical Novels", volume: nil }],
                 extra_info: ["unabridged"] }]
  )
  @outputs[:features_sources][:"variant with extra info and series from Head also"] = [a_head_extras]

  a_variant_length = item_hash(
    title:,
    variants: [a_variant_extra_info[:variants].first.merge(isbn: isbn, length: 247),
               a_variant_extra_info[:variants].last.merge(length: "7:03")],
  )
  @outputs[:features_sources][:"length after sources ISBN and before extra info"] = [a_variant_length]

  a_variant_sources = item_hash(
    title:,
    variants: [a_variant_length[:variants].first.merge(sources: three_sources),
               a_variant_length[:variants].last],
  )
  @outputs[:features_sources][:"multiple sources allowed in variant"] = [a_variant_sources]

  @outputs[:features_sources][:"optional commas can be added within and between variants"] = [a_variant_sources]



  @outputs[:features_start_dates] = {}
  a = item_hash(title: "Sapiens")
  start = { experiences: [{ spans: [{ dates: Date.parse("2020/09/01").. }] }] }
  a_start = a.deep_merge(start)
  @outputs[:features_start_dates][:"start date"] = [a_start]

  start_2 = {
    experiences: [{},
                  { spans: [{ dates: Date.parse("2021/07/15").. }] }],
  }
  a_start_2 = item_hash(**a.deep_merge(start).deep_merge(start_2))
  @outputs[:features_start_dates][:"start dates"] = [a_start_2]

  start_3 = {
    experiences: [{},
                  {},
                  { spans: [{ dates: Date.parse("2022/01/01").. }] }],
  }
  a_start_3 = item_hash(**a.deep_merge(start).deep_merge(start_2).deep_merge(start_3))
  @outputs[:features_start_dates][:"start dates in any order"] = [a_start_3]

  progress = ->(amount) { { experiences: [{ spans: [{ progress: amount }] }] } }
  a_progress_half = a_start.deep_merge(progress.call(0.5))
  @outputs[:features_start_dates][:"progress"] = [a_progress_half]

  a_progress_pages = a_start.deep_merge(progress.call(220))
  @outputs[:features_start_dates][:"progress pages"] = [a_progress_pages]

  @outputs[:features_start_dates][:"progress pages without p"] = [a_progress_pages]

  a_progress_time = a_start.deep_merge(progress.call("2:30"))
  @outputs[:features_start_dates][:"progress time"] = [a_progress_time]

  a_progress_zero = a_start.deep_merge(progress.call(0))
  @outputs[:features_start_dates][:"dnf default zero"] = [a_progress_zero]

  @outputs[:features_start_dates][:"dnf with progress"] = [a_progress_half]

  a_dnf_only = a.deep_merge(progress.call(0.5))
  @outputs[:features_start_dates][:"dnf only"] = [a_dnf_only]

  variant_2 = { experiences: [{ variant_index: 1 }] }
  a_variant = a_start.deep_merge(variant_2)
  @outputs[:features_start_dates][:"variant"] = [a_variant]

  a_variant_only = a.deep_merge(variant_2)
  @outputs[:features_start_dates][:"variant only"] = [a_variant_only]

  group = { experiences: [{ group: "county book club" }] }
  a_group = a_variant.deep_merge(group)
  @outputs[:features_start_dates][:"group"] = [a_group]

  a_group_only = a.deep_merge(group)
  @outputs[:features_start_dates][:"group only"] = [a_group_only]

  a_start_twice = item_hash(**a.deep_merge(start).deep_merge(start_2))
  a_start_twice_progress = a_start_twice.deep_merge(
    experiences: [{ spans: [{ progress: 0.5 }],
                    variant_index: 1 },
                  { spans: [{ progress: "2:30" }] }],
  )
  @outputs[:features_start_dates][:"all features"] = [a_start_twice_progress]



  @outputs[:features_compact_planned] = {}
  a_title = item_hash(title: "A Song for Nero",
                      variants: [{ format: :ebook }])
  @outputs[:features_compact_planned][:"title only"] = [a_title]

  a_author = a_title.merge(author: "Tom Holt")
  @outputs[:features_compact_planned][:"with author"] = [a_author]

  lexpub_and_hoopla = [{ name: "Lexpub", url: nil },
                       { name: "Hoopla", url: nil }]
  a_sources = a_author.deep_merge(variants: [{ sources: lexpub_and_hoopla }])
  @outputs[:features_compact_planned][:"with sources"] = [a_sources]

  @outputs[:features_compact_planned][:"with sources in the Sources column"] = [a_sources]

  a_full_sources = a_sources.deep_merge(
    variants: [{ isbn: "B00GW4U2TM",
                 extra_info: ["unabridged"],
                 series: [{ name: "Holt's Classical Novels", volume: nil }] }],
  )
  @outputs[:features_compact_planned][:"with fuller Head and Sources columns"] = [a_full_sources]

  a_full_sources_minus_isbn = a_full_sources.deep_merge(variants: [{ isbn: nil }])
  @outputs[:features_compact_planned][:"with sources and extra info"] = [a_full_sources_minus_isbn]

  b_sources = item_hash(
    title: "True Grit",
    variants: [{ format: :audiobook,
                sources: [{ name: "Lexpub" }] }],
  )
  @outputs[:features_compact_planned][:"multiple"] = [a_sources, b_sources]

  @outputs[:features_compact_planned][:"multiple with source"] = [a_sources, b_sources]

  a_genre = a_sources.merge(genres: ["historical fiction"])
  b_genre = b_sources.merge(genres: ["historical fiction"])
  @outputs[:features_compact_planned][:"multiple with genre"] = [a_genre, b_genre]

  a_multi_genre = a_sources.merge(genres: ["historical fiction", "faves"])
  b_multi_genre = b_sources.merge(genres: ["historical fiction", "faves"])
  @outputs[:features_compact_planned][:"multiple with multiple genres"] = [a_multi_genre, b_multi_genre]

  @outputs[:features_compact_planned][:"multiple with genre plus source"] = [a_genre, b_genre]

  @outputs[:features_compact_planned][:"duplicate sources are ignored"] = [a_genre, b_genre]

  default_name = base_config.deep_fetch(:sources, :default_name_for_url)
  multi_source = [{ sources: [{ name: "Lexpub" },
                              { name: default_name, url: "https://www.lexpublib.org" }]}]
  a_multi_source = a_genre.deep_merge(variants: multi_source)
  b_multi_source = b_genre.deep_merge(variants: multi_source)
  @outputs[:features_compact_planned][:"multiple sources at the beginning"] = [a_multi_source, b_multi_source]

  @outputs[:features_compact_planned][:"config-defined emojis are ignored"] = [a_genre, b_genre]



  @outputs[:features_history] = {}
  a_dates_names = item_hash(
    title: "Fullstack Ruby",
    experiences: [{ spans: [
      { dates: Date.parse("2021/12/6")..Date.parse("2021/12/6"),
        name: "#1 Why Ruby2JS is a Game Changer" },
      { dates: Date.parse("2021/12/21")..Date.parse("2021/12/21"),
        name: "#2 Componentized View Architecture FTW!" },
      { dates: Date.parse("2021/2/22")..Date.parse("2021/2/22"),
        name: "#3 String-Based Templates vs. DSLs" }] }],
  )
  @outputs[:features_history][:"dates and names"] = [a_dates_names]

  a_time_amounts = a.merge(
    experiences: [{ spans: [
      a.deep_fetch(:experiences, 0, :spans).first.merge(amount: "0:35" ),
      a.deep_fetch(:experiences, 0, :spans).first.merge(amount: "0:45" ),
      a.deep_fetch(:experiences, 0, :spans).first.merge(amount: "0:45" )] }],
  )
  @outputs[:features_history][:"time amounts"] = [a_time_amounts]



  @outputs[:all_columns] = {}
  a = item_hash(title: "Sapiens")
  start = { experiences: [{ spans: [{ dates: Date.parse("2020/09/01").. }] }] }
  a_start = a.deep_merge(start)
  a_start_format = a_start.deep_merge(variants: [{ format: :print }])
  @outputs[:all_columns][:"empty Sources column doesn't prevent variant from elsewhere"] = [a_start_format]

  a_variant_length = item_hash(
    title: "Goatsong",
    variants: [a_variant_extra_info[:variants].first.merge(isbn: isbn, length: 247),
               a_variant_extra_info[:variants].last.merge(length: "7:03")],
  )
  a_variant_length_with_experience =
    a_variant_length.deep_merge(
      experiences: [{
        spans: [{ dates: Date.parse("2020/09/01").., amount: 247 }],
        variant_index: 0
      }]
    )
  @outputs[:all_columns][:"default span amount is the correct length via variants"] =
    [a_variant_length_with_experience]

  sapiens = item_hash(
    title: "Sapiens: A Brief History of Humankind",
    variants:    [{ format: :audiobook,
                    sources: [{ name: "Hoopla" }],
                    isbn: "B00ICN066A",
                    length: "15:17" }],
    experiences: [{ spans: [{ dates: Date.parse("2021/09/20")..,
                              amount: "15:17" }] }],
    genres: ["history"],
    notes: [
      { content: "Easy to criticize, but I like the emphasis on human happiness." },
      { content: "Ch. 5: \"We did not domesticate wheat. It domesticated us.\"" },
      { content: "Discussion of that point: https://www.reddit.com/r/AskHistorians/comments/2ttpn2" },
    ],
  )
  goatsong = item_hash(
    rating: 5,
    author: "Tom Holt",
    title: "Goatsong",
    variants:    [{ format: :print,
                    sources: [{ name: "Lexpub" }],
                    isbn: "0312038380",
                    length: 247 }],
    experiences: [{ spans: [{ dates: Date.parse("2019/05/28")..Date.parse("2019/06/13"),
                              amount: 247,
                              progress: 1.0 }] },
                  { spans: [{ dates: Date.parse("2020/05/01")..,
                              amount: 247 }] }],
    genres: %w[history fiction],
  )
  @outputs[:all_columns][:"realistic examples: in progress books"] = [sapiens, goatsong]

  insula = item_hash(
    rating: 4,
    author: "Robert Louis Stevenson",
    title: "Insula Thesauraria",
    variants:    [{ format: :print,
                    series: [{ name: "Mount Hope Classics" }],
                    isbn: "1533694567",
                    length: 260,
                    extra_info: ["trans. Arcadius Avellanus"] }],
    experiences: [{ spans: [{ dates: Date.parse("2020/10/20")..Date.parse("2021/08/31"),
                              amount: 260,
                              progress: 1.0 }],
                    group: "Latin reading group" }],
    genres: %w[latin fiction],
  )
  cat_mojo = item_hash(
    rating: 2,
    title: "Total Cat Mojo",
    variants:    [{ format: :audiobook,
                    sources: [{ name: "gift from neighbor Edith" }],
                    isbn: "B01NCYY3BV",
                    length: "10:13" }],
    experiences: [{ spans: [{ dates: Date.parse("2020/03/21")..Date.parse("2020/04/01"),
                              amount: "10:13",
                              progress: 0.5 }] }],
    genres: %w[cats],
    notes: [{ private?: true, content: "I would've felt bad if I hadn't tried." }],
  )
  podcast_1 = item_hash(
    rating: 1,
    title: "FiveThirtyEight Politics",
    variants:    [{ format: :audio,
                    length: "0:30" }],
    experiences: [{ spans: [{ dates: Date.parse("2021/08/02")..Date.parse("2021/08/02"),
                              amount: "0:30",
                              progress: 0 }],
                    variant_index: 0 }],
    genres: %w[politics podcast],
    notes: [{ content: "Not very deep. Disappointing." }],
  )
  podcast_2 = podcast_1.merge(title: "The NPR Politics Podcast")
  podcast_3 = podcast_1.merge(title: "Pod Save America")
  what_if = item_hash(
    rating: 5,
    author: "Randall Munroe",
    title: "What If?: Serious Scientific Answers to Absurd Hypothetical Questions",
    variants:    [{ format: :audiobook,
                    sources: [{ name: "Lexpub" }],
                    isbn: "B00LV2F1ZA",
                    length: "6:36",
                    extra_info: ["unabridged", "published 2016"] },
                  { format: :ebook,
                    sources: [{ name: "Amazon" }],
                    isbn: "B00IYUYF4A",
                    length: 320,
                    extra_info: ["published 2014"] }],
    experiences: [{ spans: [{ dates: Date.parse("2021/08/01")..Date.parse("2021/08/15"),
                              amount: "6:36",
                              progress: 1.0 }],
                    variant_index: 0 },
                  { spans: [{ dates: Date.parse("2021/08/16")..Date.parse("2021/08/28"),
                              amount: 320,
                              progress: 1.0 }],
                    group: "with Sam",
                    variant_index: 1 },
                  { spans: [{ dates: Date.parse("2021/09/01")..Date.parse("2021/09/10"),
                              amount: "6:36",
                              progress: 1.0 }],
                    variant_index: 0 }],
    genres: %w[science],
    notes: [
      { content: "Favorites: Global Windstorm, Relativistic Baseball, Laser Pointer, Hair Dryer, Machine-Gun Jetpack, Neutron Bullet." },
      { blurb?: true, content: "It's been a long time since I gave highest marks to a \"just for fun\" book, but wow, this was fun. So fun that after listening to the audiobook, I immediately proceeded to read the book, for its illustrations. If I'd read this as a kid, I might have been inspired to become a scientist." },
    ],
  )
  @outputs[:all_columns][:"realistic examples: done"] = [insula, cat_mojo, podcast_1, podcast_2, podcast_3, what_if]


  alexander = item_hash(
    author: "Tom Holt",
    title: "Alexander At The World's End",
    variants:    [{ format: :ebook,
                    isbn: "B00GVG00R0",
                    length: 484 }],
    genres: ["historical fiction"],
  )
  emperor = item_hash(
    title: "How to Think Like a Roman Emperor",
    variants:  [{ format: :ebook }],
  )
  born_crime = item_hash(
    author: "Trevor Noah",
    title: "Born a Crime",
    variants:  [{ format: :audiobook,
                  sources: [{ name: "Lexpub" },
                            { name: "Jeffco" }] }],
  )
  nero = item_hash(
    author: "Tom Holt",
    title: "A Song for Nero",
    variants:  [{ format: :ebook }],
    genres: ["historical fiction"],
  )
  true_grit = item_hash(
    title: "True Grit",
    variants:  [{ format: :audiobook,
                  sources: [{ name: "Lexpub" }] }],
    genres: ["historical fiction"],
  )
  lebowski = item_hash(
    title: "Two Gentlemen of Lebowski",
    variants:  [{ format: :audiobook,
                  sources: [{ name: base_config.deep_fetch(:sources, :default_name_for_url),
                              url: "https://www.runleiarun.com/lebowski/" }] }],
    genres: ["historical fiction"],
  )
  how_to = item_hash(
    author: "Randall Munroe",
    title: "How To",
    variants:  [{ format: :print,
                  sources: [{ name: "Lexpub" }] }],
    genres: %w[science weird],
  )
  weird_earth = item_hash(
    title: "Weird Earth",
    variants:  [{ format: :audiobook,
                  sources: [{ name: "Lexpub" },
                            { name: "Hoopla" }] }],
    genres: %w[science weird],
  )
  @outputs[:all_columns][:"realistic examples: planned"] =
    [alexander, emperor, born_crime, nero, true_grit, lebowski, how_to, weird_earth]



  @outputs[:config] = {}

  @outputs[:config][:"comment_character"] = []

  a_basic = item_hash(title: "Dracula")
  @outputs[:config][:"column_separator"] = [a_basic]

  @outputs[:config][:"column_separator can be a tab"] = [a_basic]

  a_without_D_a = item_hash(title: "✅rcul")
  @outputs[:config][:"ignored_characters"] = [a_without_D_a]

  @outputs[:config][:"skip_compact_planned"] = []



  # ==== UTILITY METHODS

  def with_columns(columns)
    if columns.empty? || columns == :all
      config = base_config
    else
      if columns.delete(:compact_planned)
        columns << :sources # because some compact planned tests have the Sources column.
      end
      config = base_config.merge(enabled_columns: columns)
    end

    config
  end

  # Removes any blank hashes in arrays, i.e. any that are the same as in the
  # template in config. Data in items must already be complete, i.e. merged with
  # the item template in config.
  def tidy(hash, key)
    hash.fetch(key).map { |item_hash|
      without_blank_hashes(item_hash).to_struct
    }
  end

  def without_blank_hashes(item_hash)
    template = base_config.fetch(:item_template)

    %i[variants experiences notes].each do |attribute|
      item_hash[attribute] =
        item_hash[attribute].reject { |value| value == template[attribute].first }
    end

    # Same for inner hashes arrays at [:variants][:series] and [:variants][:sources].
    item_hash[:variants].each do |variant|
      variant[:series] =
        variant[:series].reject { |value| value == template.deep_fetch(:variants, 0, :series).first }
      variant[:sources] =
        variant[:sources].reject { |value| value == template.deep_fetch(:variants, 0, :sources).first }
    end

    # Same for inner hash array at [:experiences][:spans].
    item_hash[:experiences].each do |variant|
      variant[:spans] =
        variant[:spans].reject { |value| value == template.deep_fetch(:experiences, 0, :spans).first }
    end

    item_hash
  end



  # ==== TESTS

  ## TESTS: ENABLING COLUMNS
  inputs[:enabled_columns].each do |name, file_str|
    columns = name.to_s.split(", ").map(&:to_sym)
    define_method("test_enabled_columns_#{columns.join("_")}") do
      columns_config = with_columns(columns)
      exp = tidy(outputs[:enabled_columns], name)
      act = Reading.parse(string: file_str, config: columns_config)
      # debugger unless exp == act
      assert_equal exp, act,
        "Failed to parse with these columns enabled: #{name}"
    end
  end

  ## TESTS: FEATURES OF SINGLE COLUMNS
  inputs.keys.select { |key| key.start_with?("features_") }.each do |group_name|
    inputs[group_name].each do |name, file_str|
      columns_sym = group_name[group_name.to_s.index("_") + 1..-1].to_sym
      columns = columns_sym.to_s.split(", ").map(&:to_sym)
      main_column_humanized = columns.first.to_s.tr("_", " ").capitalize
      define_method("test_#{columns_sym}_feature_#{name}") do
        columns_config = with_columns(columns + [:head])
        exp = tidy(outputs[group_name], name)
        act = Reading.parse(string: file_str, config: columns_config)
        # debugger unless exp == act
        assert_equal exp, act,
          "Failed to parse this #{main_column_humanized} column feature: #{name}"
      end
    end
  end

  ## TESTS: ALL COLUMNS
  inputs[:all_columns].each do |name, file_str|
    define_method("test_all_columns_#{name}") do
      columns_config = with_columns(:all)
      exp = tidy(outputs[:all_columns], name)
      act = Reading.parse(string: file_str, config: columns_config)
      # debugger unless exp == act
      assert_equal exp, act,
        "Failed to parse this all-columns example: #{name}"
    end
  end

  ## TESTS: ERRORS
  inputs[:errors].each do |error, inputs_hash|
    inputs_hash.each do |name, file_str|
      define_method("test_error_#{name}") do
        columns_config = with_columns(:all)
        if name.start_with? "OK: " # Should not raise an error.
          refute_nil Reading.parse(string: file_str, config: columns_config)
        else
          assert_raises error, "Failed to raise #{error} for: #{name}" do
            Reading.parse(string: file_str, config: columns_config)
          end
        end
      end
    end
  end

  ## TESTS: CUSTOM CONFIG
  inputs[:config].each do |name, (file_str, custom_config)|
    define_method("test_config_#{name}") do
      exp = tidy(outputs[:config], name)
      act = Reading.parse(string: file_str, config: custom_config)
      # debugger unless exp == act
      assert_equal exp, act,
        "Failed to parse this config example: #{name}"
    end
  end
end
