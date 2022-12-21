$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "test_helper"

require "reading/csv"

class CSVParseTest < Minitest::Test
  using Reading::Util::HashDeepMerge
  using Reading::Util::HashArrayDeepFetch
  using Reading::Util::HashToStruct

  self.class.attr_reader :files, :items, :base_config

  def files
    self.class.files
  end

  def items
    self.class.items
  end

  def base_config
    self.class.base_config
  end

  custom_config =
    {
      errors:
        {
          handle_error: lambda do |error|
              raise error
            end
        }
    }
  @base_config = Reading::Config.new(custom_config).hash

  @files = {}

  # ==== TEST INPUT

  ## TEST INPUT: ENABLING COLUMNS
  # In the columns tests, the Files in the heredocs below are each parsed with
  # only the columns enabled that are listed in the hash key. This tests basic
  # functionality of each column, and a few possible combinations of columns.
  @files[:enabled_columns] = {}
  @files[:enabled_columns][:"head"] = <<~EOM.freeze
    \\Author - Title
    Sapiens
    Goatsong
    How To
  EOM
  @files[:enabled_columns][:"head, dates_finished"] = <<~EOM.freeze
    \\Author - Title|Dates finished
    Sapiens
    Goatsong|2020/5/30
    How To
  EOM
  @files[:enabled_columns][:"head, dates_started"] = <<~EOM.freeze
    Sapiens|2021/9/1
    Goatsong|2020/5/1
    How To
  EOM
  @files[:enabled_columns][:"head, dates_started, dates_finished"] = <<~EOM.freeze
    Sapiens|2021/9/1
    Goatsong|2020/5/1|2020/5/30
    How To
  EOM
  @files[:enabled_columns][:"rating, head, dates_started, dates_finished"] = <<~EOM.freeze
    |Sapiens|2021/9/1
    5|Goatsong|2020/5/1|2020/5/30
    |How To
  EOM
  # length but no sources
  @files[:enabled_columns][:"rating, head, dates_started, dates_finished, length"] = <<~EOM.freeze
    |Sapiens|2021/9/1||15:17
    5|Goatsong|2020/5/1|2020/5/30|247
    |How To
  EOM
  # sources but no length
  @files[:enabled_columns][:"rating, head, sources, dates_started, dates_finished"] = <<~EOM.freeze
    |Sapiens|Vail Library B00ICN066A|2021/9/1
    5|Goatsong|0312038380|2020/5/1|2020/5/30
    |How To
  EOM
  # sources and length
  @files[:enabled_columns][:"rating, head, sources, dates_started, dates_finished, length"] = <<~EOM.freeze
    |Sapiens|Vail Library B00ICN066A|2021/9/1||15:17
    5|Goatsong|0312038380|2020/5/1|2020/5/30|247
    |How To
  EOM



  ## TEST INPUT: CUSTOM COLUMNS
  # The type of the custom column is indicated by the hash key.
  @files[:custom_columns] = {}
  @files[:custom_columns][:numeric] = <<~EOM.freeze
    \\Rating|Head|Sources|Dates started|Dates finished|Length|Surprise factor|Family friendliness
    |Sapiens|Vail Library B00ICN066A|2021/9/1||15:17|6|3.9
    5|Goatsong|0312038380|2020/5/1|2020/5/30|247|9
    |How To
  EOM
  @files[:custom_columns][:text] = <<~EOM.freeze
    \\Rating|Head|Sources|Dates started|Dates finished|Length|Mood|Will reread?
    |Sapiens|Vail Library B00ICN066A|2021/9/1||15:17|apprehensive|yes
    5|Goatsong|0312038380|2020/5/1|2020/5/30|247|tragicomic
    |How To
  EOM



  ## TEST INPUT: FEATURES OF SINGLE COLUMNS
  # In each the features tests, a single column is enabled (specified in the
  # hash key) and a bunch of possible content for that column is tested. These
  # are the columns that are more flexible and can have lots of information
  # crammed into them.
  @files[:features_head] =
  {
  :"author" =>
    "Tom Holt - Goatsong",
  :"series" =>
    "Tom Holt - Goatsong -- in The Walled Orchard",
  :"series with volume" =>
    "Tom Holt - Goatsong -- The Walled Orchard, #1",
  :"extra info" =>
    "Tom Holt - Goatsong -- unabridged -- 1990",
  :"extra info and series" =>
    "Tom Holt - Goatsong -- unabridged -- The Walled Orchard, #1 -- 1990",
  :"format" =>
    "📕Tom Holt - Goatsong",
  :"multi items" =>
    "📕Tom Holt - Goatsong, 🔊Sapiens",
  :"multi items without a comma" =>
    "📕Tom Holt - Goatsong 🔊Sapiens",
  :"multi items with a long separator" =>
    "📕Tom Holt - Goatsong -- 🔊Sapiens",
  :"progress" =>
    "50% Goatsong",
  :"progress pages" =>
    "p220 Goatsong",
  :"progress pages without p" =>
    "220 Goatsong",
  :"progress time" =>
    "2:30 Goatsong",
  :"dnf" =>
    "DNF Goatsong",
  :"dnf with progress" =>
    "DNF 50% Goatsong",
  :"dnf with multi items" =>
    "DNF 📕Tom Holt - Goatsong, 🔊Sapiens",
  :"all features" =>
    "DNF 50% 📕Tom Holt - Goatsong -- unabridged -- The Walled Orchard, #1 -- 1990, 🔊Sapiens"
  }

  # The Head column is enabled by default, so the strings for other single
  # columns are preceded by the Head column.
  @files[:features_sources] =
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
  :"URL source with name" =>
    "Goatsong|about Tom Holt - https://www.edlin.org/holt",
  :"URL source with name after" =>
    "Goatsong|https://www.edlin.org/holt - about Tom Holt",
  :"URL source with auto name" =>
    "Goatsong|https://archive.org/details/walledorchard0000holt",
  :"sources" =>
    "Goatsong|Little Library https://www.edlin.org/holt Lexpub",
  :"sources commas" =>
    "Goatsong|Little Library, https://www.edlin.org/holt - about Tom Holt, Lexpub",
  :"source with ISBN" =>
    "Goatsong|Little Library 0312038380",
  :"source with ISBN reversed" =>
    "Goatsong|0312038380 Little Library",
  :"sources with ISBN" =>
    "Goatsong|Little Library 0312038380 https://www.edlin.org/holt",
  :"sources with ISBN commas" =>
    "Goatsong|Little Library, 0312038380, https://www.edlin.org/holt - about Tom Holt, Lexpub",
  :"simple variants" =>
    "Goatsong|Little Library -- Lexpub",
  :"extra info can be included if format is specified" =>
    "Goatsong|📕Little Library -- unabridged -- 1990",
  :"formats can delimit variants" =>
    "Goatsong|📕Little Library -- unabridged -- 1990, 🔊Lexpub",
  :"formats can omit the preceding comma" =>
    "Goatsong|📕Little Library -- unabridged -- 1990 🔊Lexpub",
  :"formats can be preceded by a long separator" =>
    "Goatsong|📕Little Library -- unabridged -- 1990 -- 🔊Lexpub",
  :"length after sources ISBN and before extra info" =>
    "Goatsong|📕Little Library 0312038380 247 -- unabridged -- 1990, 🔊Lexpub 7:03",
  :"multiple sources allowed in variant" =>
    "Goatsong|📕Little Library, 0312038380, https://www.edlin.org/holt - about Tom Holt, Lexpub, 247 -- unabridged -- 1990, 🔊Lexpub 7:03",
  }

  @files[:features_dates_started] =
  {
  :"date started" =>
    "Sapiens|2020/09/01",
  :"dates started" =>
    "Sapiens|2020/09/01, 2021/07/15",
  :"progress" =>
    "Sapiens|50% 2020/09/01",
  :"progress pages" =>
    "Sapiens|220p 2020/09/01",
  :"progress pages without p" =>
    "Sapiens|220 2020/09/01",
  :"progress time" =>
    "Sapiens|2:30 2020/09/01",
  :"dnf" =>
    "Sapiens|DNF 2020/09/01",
  :"dnf with progress" =>
    "Sapiens|DNF 50% 2020/09/01",
  :"variant" =>
    "Sapiens|2020/09/01 v2",
  :"group can be indicated at the very end" =>
    "Sapiens|2020/09/01 v2 🤝🏼 county book club",
  :"group can be without text" =>
    "Sapiens|2020/09/01 v2 🤝🏼",
  :"other text before or after dates is ignored" =>
    "Sapiens|instantly hooked 2020/09/01 at the beach",
  :"all features" =>
    "Sapiens|DNF 50% instantly hooked 2020/09/01 at the beach v2, 2:30 2021/07/15",
  }

  # The compact_planned part (unlike in other :features_x) is merely semantic;
  # it has no effect in set_columns below.
  @files[:features_compact_planned] =
  {
  :"title only" =>
    "\\⚡A Song for Nero",
  :"with author" =>
    "\\⚡Tom Holt - A Song for Nero",
  :"with sources" =>
    "\\⚡A Song for Nero @Little Library @Hoopla",
  :"with genre" =>
    "\\HISTORICAL FICTION: ⚡A Song for Nero",
  :"emojis are ignored" =>
    "\\❓HISTORICAL FICTION:⚡💲A Song for Nero ✅@Little Library @Hoopla",
  :"multiple, titles only" =>
    "\\⚡A Song for Nero 🔊True Grit",
  :"multiple, everything" =>
    "\\HISTORICAL FICTION: ⚡Tom Holt - A Song for Nero @Little Library @Hoopla 🔊True Grit @Lexpub",
  }

  @files[:features_history] =
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



  ## TEST INPUT: EXAMPLES
  # Realistic examples from the reading.csv template:
  # https://github.com/fpsvogel/reading/blob/main/doc/reading.csv
  @files[:examples] = {}
  @files[:examples][:"in progress"] = <<~EOM.freeze
    \\Rating|Format, Author, Title|Sources, ISBN/ASIN|Dates started, Progress|Dates finished|Genres|Length|Notes|History
    \\------ IN PROGRESS
    |🔊Sapiens: A Brief History of Humankind|Vail Library B00ICN066A|2021/09/20||history, wisdom|15:17|💬History with a sociological bent, with special attention paid to human happiness. -- Ch. 5: "We did not domesticate wheat. It domesticated us." -- End of ch. 8: the ubiquity of patriarchal societies is so far unexplained. It would make more sense for women (being on average more socially adept) to have formed a matriarchal society as among the bonobos. -- Ch. 19: are we happier in modernity? It's doubtful.
    5|50% 📕Tom Holt - Goatsong: A Novel of Ancient Athens -- The Walled Orchard, #1|0312038380|2019/05/28, 2020/05/01, 2021/08/17|2019/06/13, 2020/05/23|historical fiction|247
  EOM
  @files[:examples][:"done"] = <<~EOM.freeze
    \\------ DONE
    4|📕Robert Louis Stevenson - Insula Thesauraria -- in Mount Hope Classics -- trans. Arcadius Avellanus -- unabridged|1533694567|2020/10/20 🤝🏼 weekly Latin reading with Sean and Dennis|2021/08/31|latin, novel|8:18|Paper on Avellanus by Patrick Owens: https://linguae.weebly.com/arcadius-avellanus.html -- Arcadius Avellanus: Erasmus Redivivus (1947): https://ur.booksc.eu/book/18873920/05190d
    2|🔊Total Cat Mojo|gift from neighbor Edith B01NCYY3BV|DNF 50% 2020/03/21, DNF 4:45 2021/08/06|2020/04/01, 2021/08/11|cats|10:13|🔒I would've felt bad if I hadn't tried.
    1|DNF 🎤FiveThirtyEight Politics 🎤The NPR Politics Podcast 🎤Pod Save America||2021/08/02|2021/08/02|politics, podcast|0:30|Not very deep. Disappointing.
    5|Randall Munroe - What If?: Serious Scientific Answers to Absurd Hypothetical Questions|🔊Lexpub B00LV2F1ZA 6:36 -- unabridged -- published 2016, ⚡Amazon B00IYUYF4A 320 -- published 2014|2021/08/01, 2021/08/16 v2 🤝🏼 with Sam, 2021/09/01|2021/08/15, 2021/08/28, 2021/09/10|science||Favorites: Global Windstorm, Relativistic Baseball, Laser Pointer, Hair Dryer, Machine-Gun Jetpack, Neutron Bullet. -- 💬It's been a long time since I gave highest marks to a "just for fun" book, but wow, this was fun. So fun that after listening to the audiobook, I immediately proceeded to read the book, for its illustrations. If I'd read this as a kid, I might have been inspired to become a scientist.
  EOM
  @files[:examples][:"planned"] = <<~EOM.freeze
    \\------ PLANNED
    |⚡Tom Holt - A Song for Nero|B00GW4U2TM|||historical fiction|580
  EOM
  @files[:examples][:"single compact planned"] = <<~EOM.freeze
    \\------ PLANNED
    \\⚡How to Think Like a Roman Emperor
    \\🔊Trevor Noah - Born a Crime @Lexpub @Jeffco
  EOM
  @files[:examples][:"multi compact planned"] = <<~EOM.freeze
    \\------ PLANNED
    \\HISTORICAL FICTION: ⚡Tom Holt - A Song for Nero 🔊True Grit @Lexpub 🔊Two Gentlemen of Lebowski @https://www.runleiarun.com/lebowski/
    \\SCIENCE: 📕Randall Munroe - How To @Lexpub 🔊Weird Earth @Hoopla @Lexpub
  EOM



  ## TEST INPUT: ERRORS
  # Bad input that should raise an error.
  @files[:errors] = {}
  @files[:errors][Reading::InvalidDateError] =
  {
  :"date started content without a date" =>
    "|Sapiens||no date here|2019/01/01",
  :"date finished content without a date" =>
    "|Sapiens||2020/01/01|no date here",
  :"incomplete date is the same as no date" =>
    "|Sapiens||2020/01|2019/01/01",
  :"conjoined dates" =>
    "|Sapiens||2020/01/01 2019/01/01",
  :"unparsable date" =>
    "|Sapiens||2020/01/32|2019/01/01",
  :"end date before start date" =>
    "|Sapiens||2020/01/01|2019/01/01",
  :"start dates out of order" =>
    "|Sapiens||2020/01/01, 2019/01/01",
  :"end date after the next start date for the same variant" =>
    "|Sapiens||2020/01/01, 2020/02/01|2020/03/01, ",
  :"OK: end date after the next start date for different variants" =>
    "|Sapiens||2020/01/01, 2020/02/01 v2|2020/03/01, ",
  }



  # ==== EXPECTED DATA
  # The results of parsing the above Files are expected to equal these hashes.

  def self.item_hash(**partial_hash)
    # This merge is not the same as Reading::Util::HashDeepMerge. This one uses the
    # first (empty) subhashes in the item template, for example in :variants and
    # :experiences in the item template.
    base_config.deep_fetch(:item, :template).merge(partial_hash) do |key, old_value, new_value|
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

  @items = {}
  @items[:enabled_columns] = {}
  a = item_hash(title: "Sapiens")
  b = item_hash(title: "Goatsong")
  c = item_hash(title: "How To")
  @items[:enabled_columns][:"head"] = [a, b, c]

  b_finished_inner = { experiences: [{ spans: [{ dates: ..Date.parse("2020/5/30") }] }] }
  b_finished = b.deep_merge(b_finished_inner)
  @items[:enabled_columns][:"head, dates_finished"] = [a, b_finished, c]

  a_started = a.deep_merge(experiences: [{ spans: [{ dates: Date.parse("2021/9/1").. }] }])
  b_started = b.deep_merge(experiences: [{ spans: [{ dates: Date.parse("2020/5/1").. }] }])
  @items[:enabled_columns][:"head, dates_started"] = [a_started, b_started, c]

  a = a_started
  b = item_hash(
    title: "Goatsong",
    experiences: [{ spans: [{ dates: Date.parse("2020/5/1")..Date.parse("2020/5/30") }] }],
  )
  @items[:enabled_columns][:"head, dates_started, dates_finished"] = [a, b, c]

  a = a.merge(rating: nil)
  b = b.merge(rating: 5)
  @items[:enabled_columns][:"rating, head, dates_started, dates_finished"] = [a, b, c]

  a_length = a.deep_merge(variants: [{ length: "15:17" }])
  b_length = b.deep_merge(variants: [{ length: 247 }])
  @items[:enabled_columns][:"rating, head, dates_started, dates_finished, length"] = [a_length, b_length, c]

  a_sources = a.deep_merge(variants: [{ isbn: "B00ICN066A",
                              sources: [{ name: "Vail Library", url: nil }] }])
  b_sources = b.deep_merge(variants: [{ isbn: "0312038380" }])
  @items[:enabled_columns][:"rating, head, sources, dates_started, dates_finished"] = [a_sources, b_sources, c]

  a = a_sources.deep_merge(variants: [{ length: "15:17" }])
  b = b_sources.deep_merge(variants: [{ length: 247 }])
  @items[:enabled_columns][:"rating, head, sources, dates_started, dates_finished, length"] = [a, b, c]



  @items[:custom_columns] = {}
  a_custom_numeric = a.merge(surprise_factor: 6,
                            family_friendliness: 3.9)
  b_custom_numeric = b.merge(surprise_factor: 9,
                            family_friendliness: 5)
  c_custom_numeric = c.merge(surprise_factor: nil,
                            family_friendliness: 5)
  @items[:custom_columns][:numeric] = [a_custom_numeric, b_custom_numeric, c_custom_numeric]

  a_custom_text = a.merge(mood: "apprehensive",
                          will_reread: "yes")
  b_custom_text = b.merge(mood: "tragicomic",
                          will_reread: "no")
  c_custom_text = c.merge(mood: nil,
                          will_reread: "no")
  @items[:custom_columns][:text] = [a_custom_text, b_custom_text, c_custom_text]



  @items[:features_head] = {}
  a_basic = item_hash(author: "Tom Holt", title: "Goatsong")
  @items[:features_head][:"author"] = [a_basic]

  a = a_basic.deep_merge(series: [{ name: "The Walled Orchard" }])
  @items[:features_head][:"series"] = [a]

  a = a.deep_merge(series: [{ volume: 1 }])
  series_with_volume = a.slice(:series)
  @items[:features_head][:"series with volume"] = [a]

  extra_info = %w[unabridged 1990]
  variants_with_extra_info = { variants: [{ extra_info: extra_info }] }
  a = a_basic.deep_merge(variants_with_extra_info)
  @items[:features_head][:"extra info"] = [a]

  a = a.merge(series_with_volume)
  @items[:features_head][:"extra info and series"] = [a]

  a_with_format = a_basic.deep_merge(variants: [{ format: :print }])
  @items[:features_head][:"format"] = [a_with_format]

  b = item_hash(title: "Sapiens", variants: [{ format: :audiobook }])
  @items[:features_head][:"multi items"] = [a_with_format, b]

  @items[:features_head][:"multi items without a comma"] = [a_with_format, b]

  @items[:features_head][:"multi items with a long separator"] = [a_with_format, b]

  half_progress = { experiences: [{ progress: 0.5 }] }
  a = item_hash(title: "Goatsong", **half_progress)
  @items[:features_head][:"progress"] = [a]

  a = item_hash(title: "Goatsong", experiences: [{ progress: 220 }])
  @items[:features_head][:"progress pages"] = [a]

  @items[:features_head][:"progress pages without p"] = [a]

  a = item_hash(title: "Goatsong", experiences: [{ progress: "2:30" }])
  @items[:features_head][:"progress time"] = [a]

  a = item_hash(title: "Goatsong", experiences: [{ progress: 0 }])
  @items[:features_head][:"dnf"] = [a]

  a = item_hash(title: "Goatsong", experiences: [{ progress: 0.5 }])
  @items[:features_head][:"dnf with progress"] = [a]

  a = a_with_format.deep_merge(experiences: [{ progress: 0 }])
  b = b.deep_merge(experiences: [{ progress: 0 }])
  @items[:features_head][:"dnf with multi items"] = [a, b]

  a = a.merge(series_with_volume).deep_merge(variants_with_extra_info).deep_merge(half_progress)
  b = b.deep_merge(half_progress)
  @items[:features_head][:"all features"] = [a, b]



  @items[:features_sources] = {}
  title = "Goatsong"
  a_basic = item_hash(title:)
  isbn = "0312038380"
  a = a_basic.deep_merge(variants: [{ isbn: isbn }])
  @items[:features_sources][:"ISBN-10"] = [a]

  a = a_basic.deep_merge(variants: [{ isbn: "978-0312038380" }])
  @items[:features_sources][:"ISBN-13"] = [a]

  a = a_basic.deep_merge(variants: [{ isbn: "B00GVG01HE" }])
  @items[:features_sources][:"ASIN"] = [a]

  library = { name: "Little Library", url: nil }
  a = a_basic.deep_merge(variants: [{ sources: [library] }])
  @items[:features_sources][:"source"] = [a]

  site = { name: base_config.deep_fetch(:item, :sources, :default_name_for_url),
           url: "https://www.edlin.org/holt" }
  a = a_basic.deep_merge(variants: [{ sources: [site] }])
  @items[:features_sources][:"URL source"] = [a]

  site_named = { name: "about Tom Holt", url: "https://www.edlin.org/holt" }
  a = a_basic.deep_merge(variants: [{ sources: [site_named] }])
  @items[:features_sources][:"URL source with name"] = [a]

  @items[:features_sources][:"URL source with name after"] = [a]

  site_auto_named = { name: "Internet Archive",
                      url: "https://archive.org/details/walledorchard0000holt" }
  a = a_basic.deep_merge(variants: [{ sources: [site_auto_named] }])
  @items[:features_sources][:"URL source with auto name"] = [a]

  lexpub = { name: "Lexpub", url: nil }
  three_sources = [site, library, lexpub]
  a = a_basic.deep_merge(variants: [{ sources: three_sources }])
  @items[:features_sources][:"sources"] = [a]

  three_sources_with_name = [site_named, library, lexpub]
  a = a_basic.deep_merge(variants: [{ sources: three_sources_with_name }])
  @items[:features_sources][:"sources commas"] = [a]

  a = a_basic.deep_merge(variants: [{ sources: [library],
                                        isbn: isbn }])
  @items[:features_sources][:"source with ISBN"] = [a]

  @items[:features_sources][:"source with ISBN reversed"] = [a]

  a = a_basic.deep_merge(variants: [{ sources: [site, library],
                                        isbn: isbn }])
  @items[:features_sources][:"sources with ISBN"] = [a]

  a = a_basic.deep_merge(variants: [{ sources: three_sources_with_name,
                                        isbn: isbn }])
  @items[:features_sources][:"sources with ISBN commas"] = [a]

  a = item_hash(title:,
                variants: [{ sources: [library] },
                           { sources: [lexpub] }])
  @items[:features_sources][:"simple variants"] = [a]

  a = item_hash(title:,
                variants: [{ format: :print,
                             sources: [library],
                             extra_info: extra_info }])
  @items[:features_sources][:"extra info can be included if format is specified"] = [a]

  a = item_hash(title:,
                variants: [a[:variants].first,
                              { format: :audiobook,
                                sources: [lexpub] }])
  @items[:features_sources][:"formats can delimit variants"] = [a]

  @items[:features_sources][:"formats can omit the preceding comma"] = [a]

  @items[:features_sources][:"formats can be preceded by a long separator"] = [a]

  a = item_hash(title:,
                variants: [a[:variants].first.merge(isbn: isbn, length: 247),
                           a[:variants].last.merge(length: "7:03")])
  @items[:features_sources][:"length after sources ISBN and before extra info"] = [a]

  a = item_hash(title:,
                variants: [a[:variants].first.merge(sources: three_sources_with_name),
                           a[:variants].last])
  @items[:features_sources][:"multiple sources allowed in variant"] = [a]



  @items[:features_dates_started] = {}
  a_basic = item_hash(title: "Sapiens")
  exp_started = { experiences: [{ spans: [{ dates: Date.parse("2020/09/01").. }] }] }
  a_started = a_basic.deep_merge(exp_started)
  @items[:features_dates_started][:"date started"] = [a_started]

  exp_second_started = { experiences: [{},
                                       { spans: [{ dates: Date.parse("2021/07/15").. }] }] }
  a = item_hash(**a_basic.deep_merge(exp_started).deep_merge(exp_second_started))
  @items[:features_dates_started][:"dates started"] = [a]

  exp_third_started = { experiences: [{},
                                      {},
                                      { spans: [{ dates: Date.parse("2022/01/01").. }] }] }
  z = item_hash(**a_basic.deep_merge(exp_started).deep_merge(exp_second_started).deep_merge(exp_third_started))
  @items[:features_dates_started][:"dates started in any order"] = [z]

  exp_progress = ->(amount) { { experiences: [{ progress: amount }] } }
  a_halfway = a_started.deep_merge(exp_progress.call(0.5))
  @items[:features_dates_started][:"progress"] = [a_halfway]

  a = a_started.deep_merge(exp_progress.call(220))
  @items[:features_dates_started][:"progress pages"] = [a]

  @items[:features_dates_started][:"progress pages without p"] = [a]

  a = a_started.deep_merge(exp_progress.call("2:30"))
  @items[:features_dates_started][:"progress time"] = [a]

  a = a_started.deep_merge(exp_progress.call(0))
  @items[:features_dates_started][:"dnf"] = [a]

  @items[:features_dates_started][:"dnf with progress"] = [a_halfway]

  exp_v2 = { experiences: [{ variant_index: 1 }] }
  a_variant = a_started.deep_merge(exp_v2)
  @items[:features_dates_started][:"variant"] = [a_variant]

  a = a_variant.deep_merge(experiences: [{ group: "county book club" }])
  @items[:features_dates_started][:"group can be indicated at the very end"] = [a]

  a = a_variant.deep_merge(experiences: [{ group: "" }])
  @items[:features_dates_started][:"group can be without text"] = [a]


  @items[:features_dates_started][:"other text before or after dates is ignored"] = [a_started]

  a_many = item_hash(**a_basic.deep_merge(exp_started).deep_merge(exp_second_started))
  a = a_many.deep_merge(experiences: [{ progress: 0.5,
                                        variant_index: 1 },
                                      { progress: "2:30" }])
  @items[:features_dates_started][:"all features"] = [a]



  @items[:features_compact_planned] = {}
  a = item_hash(title: "A Song for Nero",
                variants: [{ format: :ebook }])
  @items[:features_compact_planned][:"title only"] = [a]

  a_author = a.merge(author: "Tom Holt")
  @items[:features_compact_planned][:"with author"] = [a_author]

  little_and_hoopla = [{ name: "Little Library", url: nil },
                       { name: "Hoopla", url: nil }]
  a_sources = a.deep_merge(variants: [{ sources: little_and_hoopla }])
  @items[:features_compact_planned][:"with sources"] = [a_sources]

  a_genre = a.merge(genres: ["historical fiction"])
  @items[:features_compact_planned][:"with genre"] = [a_genre]

  a_emojis_ignored = a_sources.merge(genres: ["historical fiction"])
  @items[:features_compact_planned][:"emojis are ignored"] = [a_emojis_ignored]

  b = item_hash(title: "True Grit",
                variants: [{ format: :audiobook }])
  @items[:features_compact_planned][:"multiple, titles only"] = [a, b]

  a_all = a_author
    .deep_merge(variants: a_sources[:variants])
    .merge(genres: ["historical fiction"])
  b_all = b.deep_merge(genres: ["historical fiction"],
                       variants: [{ sources: [{ name: "Lexpub", url: nil }] }])
  @items[:features_compact_planned][:"multiple, everything"] = [a_all, b_all]



  @items[:features_history] = {}
  a = item_hash(
    title: "Fullstack Ruby",
    experiences: [{ spans: [
      { dates: Date.parse("2021/12/6")..Date.parse("2021/12/6"),
        description: "#1 Why Ruby2JS is a Game Changer" },
      { dates: Date.parse("2021/12/21")..Date.parse("2021/12/21"),
        description: "#2 Componentized View Architecture FTW!" },
      { dates: Date.parse("2021/2/22")..Date.parse("2021/2/22"),
        description: "#3 String-Based Templates vs. DSLs" }] }],
  )
  @items[:features_history][:"dates and descriptions"] = [a]

  a = a.merge(
    experiences: [{ spans: [
      a.deep_fetch(:experiences, 0, :spans).first.merge(amount: "0:35" ),
      a.deep_fetch(:experiences, 0, :spans).first.merge(amount: "0:45" ),
      a.deep_fetch(:experiences, 0, :spans).first.merge(amount: "0:45" )] }],
  )
  @items[:features_history][:"time amounts"] = [a]



  @items[:examples] = {}
  sapiens = item_hash(
    title: "Sapiens: A Brief History of Humankind",
    variants:    [{ format: :audiobook,
                    sources: [{ name: "Vail Library" }],
                    isbn: "B00ICN066A",
                    length: "15:17" }],
    experiences: [{ spans: [{ dates: Date.parse("2021/09/20").. }] }],
    genres: %w[history wisdom],
    notes: [
      { blurb?: true, content: "History with a sociological bent, with special attention paid to human happiness." },
      { content: "Ch. 5: \"We did not domesticate wheat. It domesticated us.\"" },
      { content: "End of ch. 8: the ubiquity of patriarchal societies is so far unexplained. It would make more sense for women (being on average more socially adept) to have formed a matriarchal society as among the bonobos." },
      { content: "Ch. 19: are we happier in modernity? It's doubtful." },
    ],
  )
  goatsong = item_hash(
    rating: 5,
    author: "Tom Holt",
    title: "Goatsong: A Novel of Ancient Athens",
    series: [{ name: "The Walled Orchard",
               volume: 1 }],
    variants:    [{ format: :print,
                    isbn: "0312038380",
                    length: 247 }],
    experiences: [{ spans: [{ dates: Date.parse("2019/05/28")..Date.parse("2019/06/13") }] },
                  { spans: [{ dates: Date.parse("2020/05/01")..Date.parse("2020/05/23") }] },
                  { spans: [{ dates: Date.parse("2021/08/17").. }],
                    progress: 0.5 }],
    genres: ["historical fiction"],
  )
  @items[:examples][:"in progress"] = [sapiens, goatsong]

  insula = item_hash(
    rating: 4,
    author: "Robert Louis Stevenson",
    title: "Insula Thesauraria",
    series: [{ name: "Mount Hope Classics" }],
    variants:    [{ format: :print,
                    isbn: "1533694567",
                    length: "8:18",
                    extra_info: ["trans. Arcadius Avellanus", "unabridged"] }],
    experiences: [{ spans: [{ dates: Date.parse("2020/10/20")..Date.parse("2021/08/31") }],
                    group: "weekly Latin reading with Sean and Dennis" }],
    genres: %w[latin novel],
    notes: [
      { content: "Paper on Avellanus by Patrick Owens: https://linguae.weebly.com/arcadius-avellanus.html" },
      { content: "Arcadius Avellanus: Erasmus Redivivus (1947): https://ur.booksc.eu/book/18873920/05190d" },
    ],
  )
  cat_mojo = item_hash(
    rating: 2,
    title: "Total Cat Mojo",
    variants:    [{ format: :audiobook,
                    sources: [{ name: "gift from neighbor Edith" }],
                    isbn: "B01NCYY3BV",
                    length: "10:13" }],
    experiences: [{ spans: [{ dates: Date.parse("2020/03/21")..Date.parse("2020/04/01") }],
                    progress: 0.5 },
                  { spans: [{ dates: Date.parse("2021/08/06")..Date.parse("2021/08/11") }],
                    progress: "4:45" }],
    genres: %w[cats],
    notes: [{ private?: true, content: "I would've felt bad if I hadn't tried." }],
  )
  podcast_1 = item_hash(
    rating: 1,
    title: "FiveThirtyEight Politics",
    variants:    [{ format: :audio,
                    length: "0:30" }],
    experiences: [{ spans: [{ dates: Date.parse("2021/08/02")..Date.parse("2021/08/02") }],
                    progress: 0,
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
    experiences: [{ spans: [{ dates: Date.parse("2021/08/01")..Date.parse("2021/08/15") }],
                    variant_index: 0 },
                  { spans: [{ dates: Date.parse("2021/08/16")..Date.parse("2021/08/28") }],
                    group: "with Sam",
                    variant_index: 1 },
                  { spans: [{ dates: Date.parse("2021/09/01")..Date.parse("2021/09/10") }],
                    variant_index: 0 }],
    genres: %w[science],
    notes: [
      { content: "Favorites: Global Windstorm, Relativistic Baseball, Laser Pointer, Hair Dryer, Machine-Gun Jetpack, Neutron Bullet." },
      { blurb?: true, content: "It's been a long time since I gave highest marks to a \"just for fun\" book, but wow, this was fun. So fun that after listening to the audiobook, I immediately proceeded to read the book, for its illustrations. If I'd read this as a kid, I might have been inspired to become a scientist." },
    ],
  )
  @items[:examples][:"done"] = [insula, cat_mojo, podcast_1, podcast_2, podcast_3, what_if]


  nero = item_hash(
    author: "Tom Holt",
    title: "A Song for Nero",
    variants:    [{ format: :ebook,
                    isbn: "B00GW4U2TM",
                    length: 580 }],
    genres: ["historical fiction"],
  )
  @items[:examples][:"planned"] = [nero]

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
  @items[:examples][:"single compact planned"] = [emperor, born_crime]

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
                  sources: [{ name: base_config.deep_fetch(:item, :sources, :default_name_for_url),
                              url: "https://www.runleiarun.com/lebowski" }] }],
    genres: ["historical fiction"],
  )
  how_to = item_hash(
    author: "Randall Munroe",
    title: "How To",
    variants:  [{ format: :print,
                  sources: [{ name: "Lexpub" }] }],
    genres: %w[science],
  )
  weird_earth = item_hash(
    title: "Weird Earth",
    variants:  [{ format: :audiobook,
                  sources: [{ name: "Hoopla" },
                            { name: "Lexpub" }] }],
    genres: %w[science],
  )
  @items[:examples][:"multi compact planned"] = [nero, true_grit, lebowski, how_to, weird_earth]



  # ==== UTILITY METHODS

  NO_COLUMNS = base_config.deep_fetch(:csv, :columns).keys.map { |col| [col, false] }.to_h

  def set_columns(*columns, custom_numeric_columns: nil, custom_text_columns: nil)
    if columns.empty? || columns.first == :all
      this_config = base_config
    else
      this_columns = { columns: NO_COLUMNS.merge(columns.map { |col| [col, true] }.to_h) }
      this_config = base_config.merge(csv: base_config[:csv].merge(this_columns))
    end

    unless custom_numeric_columns.nil?
      this_config.deep_merge!(csv: { custom_numeric_columns: })
    end
    unless custom_text_columns.nil?
      this_config.deep_merge!(csv: { custom_text_columns: })
    end

    @this_config = this_config
  end

  # Removes any blank hashes in arrays, i.e. any that are the same as in the
  # template in config. Data in items must already be complete, i.e. merged with
  # the item template in config.
  def tidy(items)
    items.map { |item_hash|
      without_blank_hashes(item_hash).to_struct
    }
  end

  def without_blank_hashes(item_hash)
    template = base_config.deep_fetch(:item, :template)

    %i[series variants experiences notes].each do |attribute|
      item_hash[attribute] =
        item_hash[attribute].reject { |value| value == template[attribute].first }
    end

    # Same for inner hash array at [:variants][:sources].
    item_hash[:variants].each do |variant|
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

  def parse(string)
    csv = Reading::CSV.new(
      string,
      config: @this_config,
    )
    csv.parse
  end



  # ==== THE ACTUAL TESTS

  ## TESTS: ENABLING COLUMNS
  files[:enabled_columns].each do |set_name, file_str|
    columns = set_name.to_s.split(", ").map(&:to_sym)
    define_method("test_enabled_columns_#{columns.join("_")}") do
      set_columns(*columns)
      exp = tidy(items[:enabled_columns][set_name])
      act = parse(file_str)
      # debugger unless exp == act
      assert_equal exp, act,
        "Failed to parse with these columns enabled: #{set_name}"
    end
  end

  ## TESTS: CUSTOM COLUMNS
  def test_custom_numeric_columns
    set_columns(*%i[rating head sources dates_started dates_finished length],
                custom_numeric_columns: { surprise_factor: nil, family_friendliness: 5 })
    exp = tidy(items[:custom_columns][:numeric])
    act = parse(files[:custom_columns][:numeric])
    # debugger unless exp == act
    assert_equal exp, act
  end

  def test_custom_text_columns
    set_columns(*%i[rating head sources dates_started dates_finished length],
                custom_text_columns: { mood: nil, will_reread: "no" })
    exp = tidy(items[:custom_columns][:text])
    act = parse(files[:custom_columns][:text])
    # debugger unless exp == act
    assert_equal exp, act
  end

  ## TESTS: FEATURES OF SINGLE COLUMNS
  files.keys.select { |key| key.start_with?("features_") }.each do |group_name|
    files[group_name].each do |feat, file_str|
      columns_sym = group_name[group_name.to_s.index("_") + 1..-1].to_sym
      columns = columns_sym.to_s.split(", ").map(&:to_sym)
      main_column_humanized = columns.first.to_s.tr("_", " ").capitalize
      define_method("test_#{columns_sym}_feature_#{feat}") do
        set_columns(*columns)
        exp = tidy(items[group_name][feat])
        act = parse(file_str)
        # debugger unless exp == act
        assert_equal exp, act,
          "Failed to parse this #{main_column_humanized} column feature: #{feat}"
      end
    end
  end

  ## TESTS: EXAMPLES
  files[:examples].each do |set_name, file_str|
    define_method("test_example_#{set_name}") do
      set_columns(:all)
      exp = tidy(items[:examples][set_name])
      act = parse(file_str)
      # debugger unless exp == act
      assert_equal exp, act,
        "Failed to parse this set of examples: #{set_name}"
    end
  end

  ## TESTS: ERRORS
  files[:errors].each do |error, files_hash|
    files_hash.each do |name, file_str|
      define_method("test_example_#{name}") do
        set_columns(:all)
        if name.start_with? "OK: "
          refute_nil parse(file_str) # Should not raise an error.
        else
          assert_raises error, "Failed to raise #{error} for: #{name}" do
            parse(file_str)
          end
        end
      end
    end
  end
end
