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
          handle_error: ->(error) { raise error }
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
  :"URL source with a name from config" =>
    "Goatsong|https://archive.org/details/walledorchard0000holt",
  :"sources" =>
    "Goatsong|Little Library https://www.edlin.org/holt Lexpub",
  :"sources separated by commas" =>
    "Goatsong|Little Library https://www.edlin.org/holt Lexpub, rec. by Sam",
  :"source with ISBN" =>
    "Goatsong|Little Library 0312038380",
  :"source with ISBN in reverse order" =>
    "Goatsong|0312038380 Little Library",
  :"sources with ISBN" =>
    "Goatsong|Little Library 0312038380 https://www.edlin.org/holt",
  :"sources with ISBN separated by commas" =>
    "Goatsong|Little Library 0312038380 https://www.edlin.org/holt Lexpub, rec. by Sam",
  :"simple variants" =>
    "Goatsong|📕Little Library 📕Lexpub",
  :"variant with extra info" =>
    "Goatsong|📕Little Library -- unabridged -- 1990 🔊Lexpub",
  :"optional long separator can be added between variants" =>
    "Goatsong|📕Little Library -- unabridged -- 1990 🔊Lexpub",
  :"variant with extra info and series" =>
    "Goatsong|📕Little Library -- unabridged -- The Walled Orchard, #1 -- 1990 🔊Lexpub",
  :"length after sources ISBN and before extra info" =>
    "Goatsong|📕Little Library 0312038380 247 -- unabridged -- 1990 🔊Lexpub 7:03",
  :"multiple sources allowed in variant" =>
    "Goatsong|📕Little Library 0312038380 https://www.edlin.org/holt Lexpub 247 -- unabridged -- 1990 🔊Lexpub 7:03",
  :"optional commas can be added within and between variants" =>
    "Goatsong|📕Little Library, 0312038380, https://www.edlin.org/holt, Lexpub, 247 -- unabridged -- 1990, 🔊Lexpub 7:03",
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
    "\\⚡Tom Holt - A Song for Nero @Lexpub @Hoopla",
  :"with sources in the Sources column" =>
    "\\⚡Tom Holt - A Song for Nero|Lexpub, Hoopla",
  :"with fuller Head and Sources columns (unlikely)" =>
    "\\⚡Tom Holt - A Song for Nero -- unabridged -- in Holt's Classical Novels|Lexpub, Hoopla B00GW4U2TM",
  :"multiple with with Head and Sources columns (very unlikely)" =>
    "\\⚡Tom Holt - A Song for Nero -- unabridged -- in Holt's Classical Novels|Lexpub, Hoopla B00GW4U2TM 🔊True Grit|Lexpub",
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
    5|📕Tom Holt - Goatsong: A Novel of Ancient Athens -- The Walled Orchard, #1|0312038380|2019/05/28, 2020/05/01, 50% 2021/08/17|2019/06/13, 2020/05/23|historical fiction|247
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
    \\SCIENCE, WEIRD @Lexpub: 📕Randall Munroe - How To 🔊Weird Earth @Hoopla
  EOM



  ## TEST INPUT: ERRORS
  # Bad input that should raise an error.
  @files[:errors] = {}
  @files[:errors][Reading::InvalidDateError] =
  {
  :"date not in yyyy/mm/dd format" =>
    "|Sapiens||2019-01-01|2020/01/01",
  :"date started content without a date" =>
    "|Sapiens||no date here|2020/01/01",
  :"date finished content without a date" =>
    "|Sapiens||2019/01/01|no date here",
  :"incomplete date is the same as no date" =>
    "|Sapiens||2019/01|2020/01/01",
  :"conjoined dates" =>
    "|Sapiens||2019/01/01 2020/01/01",
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
  @files[:errors][Reading::InvalidSourceError] =
  {
  :"multiple ISBNs or ASINs for the same variant" =>
    "|Sapiens|0062316117 B00ICN066A",
  :"OK: multiple URLs but different sources" =>
    "|Sapiens|https://www.sapiens.org https://www.ynharari.com/book/sapiens-2",
  :"multiple other columns in a compact planned item when only Sources is allowed" =>
    "\\⚡Tom Holt - A Song for Nero|Lexpub, Hoopla|2022/12/21",
  }
  @files[:errors][Reading::InvalidHeadError] =
  {
  :"blank Head column" =>
    "|",
  :"missing title" =>
    "|📕",
  :"missing title after author" =>
    "|📕Mark Twain - ",
  :"missing title in compact planned row" =>
    "\\📕",
  :"missing title after author in compact planned row" =>
    "\\📕Mark Twain - ",
  }
  @files[:errors][Reading::InvalidRatingError] =
  {
  :"non-numeric rating" =>
    "a|Sapiens",
  }
  # These are examples of missing columns that do NOT raise an error during parsing.
  # I *could* add more validations to avoid these, but for me these never happen
  # because I view my reading.csv with color-coded columns (Rainbow CSV extension
  # for VS Code). Even so, I'm documenting these odd cases here.
  @files[:errors][Reading::Error] =
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

  a_length_and_amount = { variants: [{ length: "15:17" }],
                          experiences: [{ spans: [{ amount: "15:17" }] }] }
  b_length_and_amount = { variants: [{ length: 247 }],
                          experiences: [{ spans: [{ amount: 247 }] }] }
  a_length = a.deep_merge(a_length_and_amount)
  b_length = b.deep_merge(b_length_and_amount)
  @items[:enabled_columns][:"rating, head, dates_started, dates_finished, length"] = [a_length, b_length, c]

  a_sources = a.deep_merge(variants: [{ isbn: "B00ICN066A",
                          sources: [{ name: "Vail Library" }] }])
  b_sources = b.deep_merge(variants: [{ isbn: "0312038380" }])
  @items[:enabled_columns][:"rating, head, sources, dates_started, dates_finished"] = [a_sources, b_sources, c]

  a = a_sources.deep_merge(a_length_and_amount)
  b = b_sources.deep_merge(b_length_and_amount)
  @items[:enabled_columns][:"rating, head, sources, dates_started, dates_finished, length"] = [a, b, c]



  @items[:custom_columns] = {}
  a_custom_numeric = a.merge(surprise_factor: 6.0,
                            family_friendliness: 3.9)
  b_custom_numeric = b.merge(surprise_factor: 9.0,
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

  a = a_basic.deep_merge(variants: [{ series: [{ name: "The Walled Orchard" }] }])
  @items[:features_head][:"series"] = [a]

  a = a.deep_merge(variants: [{ series: [{ volume: 1 }] }])
  series_with_volume = a[:variants].first.slice(:series)
  @items[:features_head][:"series with volume"] = [a]

  extra_info = %w[unabridged 1990]
  variants_with_extra_info = { variants: [{ extra_info: extra_info }] }
  a = a_basic.deep_merge(variants_with_extra_info)
  @items[:features_head][:"extra info"] = [a]

  a = a.deep_merge(variants: [series_with_volume])
  @items[:features_head][:"extra info and series"] = [a]

  a_with_format = a_basic.deep_merge(variants: [{ format: :print }])
  @items[:features_head][:"format"] = [a_with_format]

  b = item_hash(title: "Sapiens", variants: [{ format: :audiobook }])
  @items[:features_head][:"multi items"] = [a_with_format, b]

  @items[:features_head][:"multi items without a comma"] = [a_with_format, b]

  @items[:features_head][:"multi items with a long separator"] = [a_with_format, b]

  half_progress = { experiences: [{ spans: [{ progress: 0.5 }] }] }
  a = item_hash(title: "Goatsong", **half_progress)
  @items[:features_head][:"progress"] = [a]

  a = item_hash(title: "Goatsong", experiences: [{ spans: [{ progress: 220 }] }])
  @items[:features_head][:"progress pages"] = [a]

  @items[:features_head][:"progress pages without p"] = [a]

  a = item_hash(title: "Goatsong", experiences: [{ spans: [{ progress: "2:30" }] }])
  @items[:features_head][:"progress time"] = [a]

  a = item_hash(title: "Goatsong", experiences: [{ spans: [{ progress: 0 }] }])
  @items[:features_head][:"dnf"] = [a]

  a = item_hash(title: "Goatsong", experiences: [{ spans: [{ progress: 0.5 }] }])
  @items[:features_head][:"dnf with progress"] = [a]

  a = a_with_format.deep_merge(experiences: [{ spans: [{ progress: 0 }] }])
  b = b.deep_merge(experiences: [{ spans: [{ progress: 0 }] }])
  @items[:features_head][:"dnf with multi items"] = [a, b]

  full_variants = variants_with_extra_info.deep_merge(variants: [series_with_volume])
  a = a.deep_merge(full_variants).deep_merge(half_progress)
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

  default_name = base_config.deep_fetch(:item, :sources, :default_name_for_url)
  site_named = { name: default_name, url: "https://www.edlin.org/holt" }
  a = a_basic.deep_merge(variants: [{ sources: [site_named] }])
  @items[:features_sources][:"URL source with name"] = [a]

  @items[:features_sources][:"URL source with name after"] = [a]

  site_auto_named = { name: "Internet Archive",
                      url: "https://archive.org/details/walledorchard0000holt" }
  a = a_basic.deep_merge(variants: [{ sources: [site_auto_named] }])
  @items[:features_sources][:"URL source with a name from config"] = [a]

  lexpub = { name: "Lexpub", url: nil }
  three_sources = [site, library, lexpub]
  a = a_basic.deep_merge(variants: [{ sources: three_sources }])
  @items[:features_sources][:"sources"] = [a]

  four_sources = three_sources + [{ name: "rec. by Sam", url: nil }]
  a = a_basic.deep_merge(variants: [{ sources: four_sources }])
  @items[:features_sources][:"sources separated by commas"] = [a]

  a = a_basic.deep_merge(variants: [{ sources: [library],
                                        isbn: isbn }])
  @items[:features_sources][:"source with ISBN"] = [a]

  @items[:features_sources][:"source with ISBN in reverse order"] = [a]

  a = a_basic.deep_merge(variants: [{ sources: [site, library],
                                        isbn: isbn }])
  @items[:features_sources][:"sources with ISBN"] = [a]

  a = a_basic.deep_merge(variants: [{ sources: four_sources,
                                        isbn: isbn }])
  @items[:features_sources][:"sources with ISBN separated by commas"] = [a]

  a = item_hash(title:,
                variants: [{ format: :print, sources: [library] },
                           { format: :print, sources: [lexpub] }])
  @items[:features_sources][:"simple variants"] = [a]

  a = item_hash(title:,
                variants: [{ format: :print,
                             sources: [library],
                             extra_info: extra_info },
                           { format: :audiobook,
                             sources: [lexpub] }])
  @items[:features_sources][:"variant with extra info"] = [a]

  @items[:features_sources][:"optional long separator can be added between variants"] = [a]

  a_with_series = a.deep_merge(variants: [{ series: [{ name: "The Walled Orchard", volume: 1 }] }])
  @items[:features_sources][:"variant with extra info and series"] = [a_with_series]

  a = item_hash(title:,
                variants: [a[:variants].first.merge(isbn: isbn, length: 247),
                           a[:variants].last.merge(length: "7:03")])
  @items[:features_sources][:"length after sources ISBN and before extra info"] = [a]

  a = item_hash(title:,
                variants: [a[:variants].first.merge(sources: three_sources),
                           a[:variants].last])
  @items[:features_sources][:"multiple sources allowed in variant"] = [a]

  @items[:features_sources][:"optional commas can be added within and between variants"] = [a]



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

  exp_progress = ->(amount) { { experiences: [{ spans: [{ progress: amount }] }] } }
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
  a = a_many.deep_merge(experiences: [{ spans: [{ progress: 0.5 }],
                                        variant_index: 1 },
                                      { spans: [{ progress: "2:30" }] }])
  @items[:features_dates_started][:"all features"] = [a]



  @items[:features_compact_planned] = {}
  a_title = item_hash(title: "A Song for Nero",
                      variants: [{ format: :ebook }])
  @items[:features_compact_planned][:"title only"] = [a_title]

  a_author = a_title.merge(author: "Tom Holt")
  @items[:features_compact_planned][:"with author"] = [a_author]

  lexpub_and_hoopla = [{ name: "Lexpub", url: nil },
                       { name: "Hoopla", url: nil }]
  a_sources = a_author.deep_merge(variants: [{ sources: lexpub_and_hoopla }])
  @items[:features_compact_planned][:"with sources"] = [a_sources]

  @items[:features_compact_planned][:"with sources in the Sources column"] = [a_sources]

  a_full_sources = a_sources.deep_merge(variants: [{ isbn: "B00GW4U2TM",
                                                    extra_info: ["unabridged"],
                                                    series: [{ name: "Holt's Classical Novels", volume: nil }] }])
  @items[:features_compact_planned][:"with fuller Head and Sources columns (unlikely)"] = [a_full_sources]

  b_sources = item_hash(title: "True Grit",
                        variants: [{ format: :audiobook,
                                    sources: [{ name: "Lexpub" }] }])

  @items[:features_compact_planned][:"multiple with with Head and Sources columns (very unlikely)"] = [a_full_sources, b_sources]

  @items[:features_compact_planned][:"multiple"] = [a_sources, b_sources]

  @items[:features_compact_planned][:"multiple with source"] = [a_sources, b_sources]

  a_genre = a_sources.merge(genres: ["historical fiction"])
  b_genre = b_sources.merge(genres: ["historical fiction"])
  @items[:features_compact_planned][:"multiple with genre"] = [a_genre, b_genre]

  a_multi_genre = a_sources.merge(genres: ["historical fiction", "faves"])
  b_multi_genre = b_sources.merge(genres: ["historical fiction", "faves"])
  @items[:features_compact_planned][:"multiple with multiple genres"] = [a_multi_genre, b_multi_genre]

  @items[:features_compact_planned][:"multiple with genre plus source"] = [a_genre, b_genre]

  @items[:features_compact_planned][:"duplicate sources are ignored"] = [a_genre, b_genre]

  default_name = base_config.deep_fetch(:item, :sources, :default_name_for_url)
  multi_source = [{ sources: [{ name: "Lexpub" },
                              { name: default_name, url: "https://www.lexpublib.org" }]}]
  a_multi_source = a_genre.deep_merge(variants: multi_source)
  b_multi_source = b_genre.deep_merge(variants: multi_source)
  @items[:features_compact_planned][:"multiple sources at the beginning"] = [a_multi_source, b_multi_source]

  @items[:features_compact_planned][:"config-defined emojis are ignored"] = [a_genre, b_genre]



  @items[:features_history] = {}
  a = item_hash(
    title: "Fullstack Ruby",
    experiences: [{ spans: [
      { dates: Date.parse("2021/12/6")..Date.parse("2021/12/6"),
        name: "#1 Why Ruby2JS is a Game Changer" },
      { dates: Date.parse("2021/12/21")..Date.parse("2021/12/21"),
        name: "#2 Componentized View Architecture FTW!" },
      { dates: Date.parse("2021/2/22")..Date.parse("2021/2/22"),
        name: "#3 String-Based Templates vs. DSLs" }] }],
  )
  @items[:features_history][:"dates and names"] = [a]

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
    experiences: [{ spans: [{ dates: Date.parse("2021/09/20")..,
                              amount: "15:17" }] }],
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
    variants:    [{ format: :print,
                    series: [{ name: "The Walled Orchard",
                              volume: 1 }],
                    isbn: "0312038380",
                    length: 247 }],
    experiences: [{ spans: [{ dates: Date.parse("2019/05/28")..Date.parse("2019/06/13"),
                              amount: 247 }] },
                  { spans: [{ dates: Date.parse("2020/05/01")..Date.parse("2020/05/23"),
                              amount: 247 }] },
                  { spans: [{ dates: Date.parse("2021/08/17")..,
                              amount: 247,
                              progress: 0.5 }] }],
    genres: ["historical fiction"],
  )
  @items[:examples][:"in progress"] = [sapiens, goatsong]

  insula = item_hash(
    rating: 4,
    author: "Robert Louis Stevenson",
    title: "Insula Thesauraria",
    variants:    [{ format: :print,
                    series: [{ name: "Mount Hope Classics" }],
                    isbn: "1533694567",
                    length: "8:18",
                    extra_info: ["trans. Arcadius Avellanus", "unabridged"] }],
    experiences: [{ spans: [{ dates: Date.parse("2020/10/20")..Date.parse("2021/08/31"),
                              amount: "8:18" }],
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
    experiences: [{ spans: [{ dates: Date.parse("2020/03/21")..Date.parse("2020/04/01"),
                              amount: "10:13",
                              progress: 0.5 }] },
                  { spans: [{ dates: Date.parse("2021/08/06")..Date.parse("2021/08/11"),
                              amount: "10:13",
                              progress: "4:45" }] }],
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
                              amount: "6:36" }],
                    variant_index: 0 },
                  { spans: [{ dates: Date.parse("2021/08/16")..Date.parse("2021/08/28"),
                              amount: 320 }],
                    group: "with Sam",
                    variant_index: 1 },
                  { spans: [{ dates: Date.parse("2021/09/01")..Date.parse("2021/09/10"),
                              amount: "6:36" }],
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
    genres: %w[science weird],
  )
  weird_earth = item_hash(
    title: "Weird Earth",
    variants:  [{ format: :audiobook,
                  sources: [{ name: "Lexpub" },
                            { name: "Hoopla" }] }],
    genres: %w[science weird],
  )
  @items[:examples][:"multi compact planned"] = [nero, true_grit, lebowski, how_to, weird_earth]



  # ==== UTILITY METHODS

  def set_columns(columns, custom_numeric_columns: nil, custom_text_columns: nil)
    if columns.empty? || columns == :all
      this_config = base_config
    else
      columns.delete(:compact_planned)
      this_config = base_config.merge(csv: { enabled_columns: columns})
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
      set_columns(columns)
      exp = tidy(items[:enabled_columns][set_name])
      act = parse(file_str)
      # debugger unless exp == act
      assert_equal exp, act,
        "Failed to parse with these columns enabled: #{set_name}"
    end
  end

  ## TESTS: CUSTOM COLUMNS
  def test_custom_numeric_columns
    set_columns(%i[rating head sources dates_started dates_finished length],
                custom_numeric_columns: { surprise_factor: nil, family_friendliness: 5 })
    exp = tidy(items[:custom_columns][:numeric])
    act = parse(files[:custom_columns][:numeric])
    # debugger unless exp == act
    assert_equal exp, act
  end

  def test_custom_text_columns
    set_columns(%i[rating head sources dates_started dates_finished length],
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
        set_columns(columns + [:head])
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
