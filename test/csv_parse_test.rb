require_relative "test_helper"
require_relative "test_base"

require "reading/csv/config"
require "reading/csv/csv"
require "reading/util/deep_merge"
require "reading/util/deep_fetch"

class CSVParseTest < TestBase
  using Reading::Util::DeepMerge
  using Reading::Util::DeepFetch

  custom_config =
    {
      errors:
        {
          handle_error: lambda do |error|
              @error_log << error
              puts error
            end
        }
    }
  @config = Reading::Config.new(custom_config).hash

  @files = {}

  ### TEST DATA

  ## TEST DATA: ENABLING COLUMNS
  # In the columns tests, the CSVs in the heredocs below are each parsed with
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



  ## TEST DATA: CUSTOM COLUMNS
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



  ## TEST DATA: FEATURES OF SINGLE COLUMNS
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
  :"length after sources ISBN and before extra info" =>
    "Goatsong|📕Little Library 0312038380 247 -- unabridged -- 1990, 🔊Lexpub 7:03",
  :"multiple sources allowed in variant" =>
    "Goatsong|📕Little Library, 0312038380, https://www.edlin.org/holt - about Tom Holt, Lexpub, 247 -- unabridged -- 1990, 🔊Lexpub 7:03",
  }

  @files[:features_dates_started] =
  {
  :"date started" =>
    "Sapiens|2020/09/01",
  :"date added" =>
    "Sapiens|2019/08/20 >",
  :"date added and started" =>
    "Sapiens|2019/08/20 > 2020/09/01",
  :"dates started" =>
    "Sapiens|2020/09/01, 2021/07/15",
  :"dates added and started" =>
    "Sapiens|2019/08/20 > 2020/09/01, 2021/07/15, 2021/09/20 >",
  :"progress" =>
    "Sapiens|50% 2020/09/01",
  :"progress must be at the beginning or immediately after date started separator" =>
    "Sapiens|2019/08/20 > 50% 2020/09/01, 50% 2021/01/01 > 2021/07/15",
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
  :"variant with just date added" =>
    "Sapiens|2019/08/20 > v2",
  :"variant can be anywhere" =>
    "Sapiens|2019/08/20 v2 >, v3 2021/07/15",
  :"group can be indicated at the very end" =>
    "Sapiens|2020/09/01 v2 🤝🏼 county book club",
  :"group can be without text" =>
    "Sapiens|2020/09/01 v2 🤝🏼",
  :"other text before or after dates is ignored" =>
    "Sapiens|found on Chirp on 2019/08/20 and recommended by Jo > instantly hooked 2020/09/01 at the beach",
  :"all features" =>
    "Sapiens|found on Chirp on 2019/08/20 and recommended by Jo > DNF 50% instantly hooked 2020/09/01 at the beach v2, 2:30 2021/07/15, 2021/09/20 > v3",
  }

  @files[:features_genres] =
  {
  :"genres" =>
    "Goatsong|novel, history",
  :"visibility" =>
    "Goatsong|novel, history, for starred friends",
  :"visibility anywhere" =>
    "Goatsong|novel, for starred friends, history",
  :"visibility alt" =>
    "Goatsong|novel, to-starred, history",
  }

  # The compact_planned part (unlike in other :features_x) is merely semantic;
  # it has no effect in set_columns below.
  @files[:features_compact_planned] =
  {
  :"title only" =>
    "\\HISTORICAL FICTION: ⚡A Song for Nero",
  :"author" =>
    "\\HISTORICAL FICTION: ⚡Tom Holt - A Song for Nero",
  :"sources" =>
    "\\HISTORICAL FICTION: ⚡A Song for Nero @Little Library @Hoopla",
  :"multiple first formats" =>
    "\\HISTORICAL FICTION: ⚡🔊A Song for Nero @Little Library @Hoopla",
  :"formats in sources" =>
    "\\HISTORICAL FICTION: ⚡🔊A Song for Nero @Little Library @📕🔊Jeffco @Hoopla @📕Lexpub",
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
  #   "War and Peace|2021/04/28-29 p115 -- 4/30-5/3 24p ---- 2022/1/1-2/15 50p",
  }



  ## TEST DATA: EXAMPLES
  # Realistic examples from the reading.csv template in Plain Reading.
  @files[:examples] = {}
  @files[:examples][:"in progress"] = <<~EOM.freeze
    \\Rating|Format, Author, Title|Sources, ISBN/ASIN|Dates added > Started, Progress|Dates finished|Genres|Length|Public notes|Blurb|Private notes|History
    \\------ IN PROGRESS
    |🔊Sapiens: A Brief History of Humankind|Vail Library B00ICN066A|2021/06/11 > 2021/09/20| |history, wisdom|15:17|Ch. 5: "We did not domesticate wheat. It domesticated us." -- End of ch. 8: the ubiquity of patriarchal societies is so far unexplained. It would make more sense for women (being on average more socially adept) to have formed a matriarchal society as among the bonobos. -- Ch. 19: are we happier in modernity? It's doubtful.|History with a sociological bent, with special attention paid to human happiness.
    5|50% 📕Tom Holt - Goatsong: A Novel of Ancient Athens -- The Walled Orchard, #1|0312038380|2019/05/28, 2020/05/01, 2021/08/17|2019/06/13, 2020/05/23|historical fiction|247
  EOM
  @files[:examples][:"done"] = <<~EOM.freeze
    \\------ DONE
    4|📕Robert Louis Stevenson - Insula Thesauraria -- in Mount Hope Classics -- trans. Arcadius Avellanus -- unabridged|1533694567|2020/10/20 🤝🏼 weekly Latin reading with Sean and Dennis|2021/08/31|latin, novel|8:18|Paper on Avellanus by Patrick Owens: https://linguae.weebly.com/arcadius-avellanus.html -- Arcadius Avellanus: Erasmus Redivivus (1947): https://ur.booksc.eu/book/18873920/05190d
    2|🔊Total Cat Mojo|gift from neighbor Edith B01NCYY3BV|DNF 50% 2020/03/21, DNF 4:45 2021/08/06|2020/04/01, 2021/08/11|cats, for friends|10:13|I would've felt bad if I hadn't tried.
    1|DNF 🎤FiveThirtyEight Politics, 🎤The NPR Politics Podcast, 🎤Pod Save America| |2021/08/02|2021/08/02|politics, podcast, for starred friends|0:30|Not very deep. Disappointing.
    5|Randall Munroe - What If?: Serious Scientific Answers to Absurd Hypothetical Questions|🔊Lexpub B00LV2F1ZA 6:36 -- unabridged -- published 2016, ⚡Amazon B00IYUYF4A 320 -- published 2014|2021/08/01, 2021/08/16 v2 🤝🏼 with Sam, 2021/09/01|2021/08/15, 2021/08/28, 2021/09/10|science| |Favorites: Global Windstorm, Relativistic Baseball, Laser Pointer, Hair Dryer, Machine-Gun Jetpack, Neutron Bullet.|It's been a long time since I gave highest marks to a "just for fun" book, but wow, this was fun. So fun that after listening to the audiobook, I immediately proceeded to read the book, for its illustrations. If I'd read this as a kid, I might have been inspired to become a scientist.
  EOM
  @files[:examples][:"planned"] = <<~EOM.freeze
    \\------ PLANNED
    |⚡Tom Holt - A Song for Nero|B00GW4U2TM| | |historical fiction|580
    |📕Randall Munroe - How To|Lexpub B07NCQTJV3|2021/06/27 >| |science|320
  EOM
  @files[:examples][:"compact planned"] = <<~EOM.freeze
    \\------ PLANNED
    \\HISTORICAL FICTION: ⚡Tom Holt - A Song for Nero, 🔊True Grit @Little Library @Hoopla, 🔊Two Gentlemen of Lebowski @https://www.runleiarun.com/lebowski/
    \\SCIENCE: 📕⚡Randall Munroe - How To @Lexpub @🔊⚡Hoopla @🔊Jeffco, 🔊Weird Earth @Hoopla @📕🔊⚡Lexpub
  EOM



  ### EXPECTED DATA
  # The results of parsing the above CSVs are expected to equal this data.

  def self.item_data(**partial_data)
    # This merge is not the same as Reading::Util::DeepMerge. This one uses an
    # array value's first hash as the template for all corresponding partial
    # data, for example in :variants and :experiences in the item template.
    config.deep_fetch(:item, :template).merge(partial_data) do |key, old_value, new_value|
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
  a = item_data(title: "Sapiens")
  b = item_data(title: "Goatsong")
  c = item_data(title: "How To")
  @items[:enabled_columns][:"head"] = [a, b, c]

  b_finished_inner = { experiences: [{ spans: [{ dates: .."2020/5/30" }] }] }
  b_finished = b.deep_merge(b_finished_inner)
  @items[:enabled_columns][:"head, dates_finished"] = [a, b_finished, c]

  a_started = a.deep_merge(experiences: [{ spans: [{ dates: "2021/9/1".. }] }])
  b_started = b.deep_merge(experiences: [{ spans: [{ dates: "2020/5/1".. }] }])
  @items[:enabled_columns][:"head, dates_started"] = [a_started, b_started, c]

  a = a_started
  b = item_data(
    title: "Goatsong",
    experiences: [{ spans: [{ dates: "2020/5/1".."2020/5/30" }] }]
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
  a_basic = item_data(author: "Tom Holt", title: "Goatsong")
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

  b = item_data(title: "Sapiens", variants: [{ format: :audiobook }])
  @items[:features_head][:"multi items"] = [a_with_format, b]

  half_progress = { experiences: [{ progress: 0.5 }] }
  a = item_data(title: "Goatsong", **half_progress)
  @items[:features_head][:"progress"] = [a]

  a = item_data(title: "Goatsong", experiences: [{ progress: 220 }])
  @items[:features_head][:"progress pages"] = [a]

  @items[:features_head][:"progress pages without p"] = [a]

  a = item_data(title: "Goatsong", experiences: [{ progress: "2:30" }])
  @items[:features_head][:"progress time"] = [a]

  a = item_data(title: "Goatsong", experiences: [{ progress: 0 }])
  @items[:features_head][:"dnf"] = [a]

  a = item_data(title: "Goatsong", experiences: [{ progress: 0.5 }])
  @items[:features_head][:"dnf with progress"] = [a]

  a = a_with_format.deep_merge(experiences: [{ progress: 0 }])
  b = b.deep_merge(experiences: [{ progress: 0 }])
  @items[:features_head][:"dnf with multi items"] = [a, b]

  a = a.merge(series_with_volume).deep_merge(variants_with_extra_info).deep_merge(half_progress)
  b = b.deep_merge(half_progress)
  @items[:features_head][:"all features"] = [a, b]



  @items[:features_sources] = {}
  title = "Goatsong"
  a_basic = item_data(title:)
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

  site = { name: config.deep_fetch(:item, :sources, :default_name_for_url),
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

  a = item_data(title:,
                variants: [{ sources: [library] },
                           { sources: [lexpub] }])
  @items[:features_sources][:"simple variants"] = [a]

  a = item_data(title:,
                variants: [{ format: :print,
                             sources: [library],
                             extra_info: extra_info }])
  @items[:features_sources][:"extra info can be included if format is specified"] = [a]

  a = item_data(title:,
                variants: [a[:variants].first,
                              { format: :audiobook,
                                sources: [lexpub] }])
  @items[:features_sources][:"formats can delimit variants"] = [a]

  a = item_data(title:,
                variants: [a[:variants].first.merge(isbn: isbn, length: 247),
                           a[:variants].last.merge(length: "7:03")])
  @items[:features_sources][:"length after sources ISBN and before extra info"] = [a]

  a = item_data(title:,
                variants: [a[:variants].first.merge(sources: three_sources_with_name),
                           a[:variants].last])
  @items[:features_sources][:"multiple sources allowed in variant"] = [a]



  @items[:features_dates_started] = {}
  a_basic = item_data(title: "Sapiens")
  exp_started = { experiences: [{ spans: [{ dates: "2020/09/01".. }] }] }
  a_started = a_basic.deep_merge(exp_started)
  @items[:features_dates_started][:"date started"] = [a_started]

  exp_added = { experiences: [{ date_added: "2019/08/20" }] }
  a = a_basic.deep_merge(exp_added)
  @items[:features_dates_started][:"date added"] = [a]

  a_added_started = a_basic.deep_merge(exp_added.deep_merge(exp_started))
  @items[:features_dates_started][:"date added and started"] = [a_added_started]

  exp_second_started = { experiences: [{},
                                       { spans: [{ dates: "2021/07/15".. }] }] }
  a = item_data(**a_basic.deep_merge(exp_started).deep_merge(exp_second_started))
  @items[:features_dates_started][:"dates started"] = [a]

  exp_third_added = { experiences: [{},
                                    {},
                                    { date_added: "2021/09/20" }] }
  a_many = item_data(**a_basic.deep_merge(exp_started).deep_merge(exp_second_started)
                              .deep_merge(exp_added).deep_merge(exp_third_added))
  @items[:features_dates_started][:"dates added and started"] = [a_many]

  exp_progress = ->(amount) { { experiences: [{ progress: amount }] } }
  a_halfway = a_started.deep_merge(exp_progress.call(0.5))
  @items[:features_dates_started][:"progress"] = [a_halfway]

  exp_second_added = { experiences: [{},
                                     { date_added: "2021/01/01" }] }
  exp_two_progresses = { experiences: [{ progress: 0.5 },
                                       { progress: 0.5 }] }
  a = item_data(**a_basic.deep_merge(exp_added).deep_merge(exp_second_added)
                          .deep_merge(exp_started).deep_merge(exp_second_started)
                          .deep_merge(exp_two_progresses))
  @items[:features_dates_started][:"progress must be at the beginning or immediately after date started separator"] = [a]

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

  a = a_basic.deep_merge(exp_added.deep_merge(exp_v2))
  @items[:features_dates_started][:"variant with just date added"] = [a]

  exp_v3 = { experiences: [{},
                           { variant_index: 2 }] }
  a = item_data(**a.deep_merge(exp_second_started).deep_merge(exp_v3))
  @items[:features_dates_started][:"variant can be anywhere"] = [a]

  a = a_variant.deep_merge(experiences: [{ group: "county book club" }])
  @items[:features_dates_started][:"group can be indicated at the very end"] = [a]

  a = a_variant.deep_merge(experiences: [{ group: "" }])
  @items[:features_dates_started][:"group can be without text"] = [a]

  @items[:features_dates_started][:"other text before or after dates is ignored"] = [a_added_started]

  a = a_many.deep_merge(experiences: [{ progress: 0.5,
                                          variant_index: 1 },
                                        { progress: "2:30" },
                                        { variant_index: 2 }])
  @items[:features_dates_started][:"all features"] = [a]



  @items[:features_genres] = {}
  a_basic = item_data(title: "Goatsong", genres: %w[novel history])
  @items[:features_genres][:"genres"] = [a_basic]

  a = a_basic.merge(visibility: 1)
  @items[:features_genres][:"visibility"] = [a]

  @items[:features_genres][:"visibility anywhere"] = [a]

  @items[:features_genres][:"visibility alt"] = [a]



  @items[:features_compact_planned] = {}
  a = item_data(title: "A Song for Nero",
                genres: ["historical fiction"],
                variants: [{ format: :ebook }])
  @items[:features_compact_planned][:"title only"] = [a]

  a_author = a.merge(author: "Tom Holt")
  @items[:features_compact_planned][:"author"] = [a_author]

  little_and_hoopla = [{ name: "Little Library", url: nil },
                       { name: "Hoopla", url: nil }]
  a_sources = a.deep_merge(variants: [{ sources: little_and_hoopla }])
  @items[:features_compact_planned][:"sources"] = [a_sources]

  a_multi_first_formats = a_sources.deep_merge(
    variants: [a_sources[:variants].first,
               a_sources[:variants].first.merge(format: :audiobook)])
  @items[:features_compact_planned][:"multiple first formats"] = [a_multi_first_formats]

  a_formats_in_sources = a_multi_first_formats.deep_merge(
    variants: [{ format: :ebook, sources: little_and_hoopla },
               { format: :audiobook, sources: little_and_hoopla.dup.insert(1, { name: "Jeffco", url: nil }) },
               { format: :print, sources: [{ name: "Jeffco", url: nil },
                                           { name: "Lexpub", url: nil }],
                 isbn: nil, length: nil, extra_info: [] }])
  @items[:features_compact_planned][:"formats in sources"] = [a_formats_in_sources]



  @items[:features_history] = {}
  a = item_data(
    title: "Fullstack Ruby",
    experiences: [{ spans: [
      { dates: Date.parse("2021/12/6")..Date.parse("2021/12/6"),
        description: "#1 Why Ruby2JS is a Game Changer" },
      { dates: Date.parse("2021/12/21")..Date.parse("2021/12/21"),
        description: "#2 Componentized View Architecture FTW!" },
      { dates: Date.parse("2021/2/22")..Date.parse("2021/2/22"),
        description: "#3 String-Based Templates vs. DSLs" }] }]
  )
  @items[:features_history][:"dates and descriptions"] = [a]

  a = a.merge(
    experiences: [{ spans: [
      a.deep_fetch(:experiences, 0, :spans).first.merge(amount: "0:35" ),
      a.deep_fetch(:experiences, 0, :spans).first.merge(amount: "0:45" ),
      a.deep_fetch(:experiences, 0, :spans).first.merge(amount: "0:45" )] }]
  )
  @items[:features_history][:"time amounts"] = [a]



  @items[:examples] = {}
  sapiens = item_data(
    title: "Sapiens: A Brief History of Humankind",
    variants:    [{ format: :audiobook,
                    sources: [{ name: "Vail Library" }],
                    isbn: "B00ICN066A",
                    length: "15:17" }],
    experiences: [{ date_added: "2021/06/11",
                    spans: [{ dates: "2021/09/20".. }] }],
    genres: %w[history wisdom],
    public_notes: ["Ch. 5: \"We did not domesticate wheat. It domesticated us.\"", "End of ch. 8: the ubiquity of patriarchal societies is so far unexplained. It would make more sense for women (being on average more socially adept) to have formed a matriarchal society as among the bonobos.", "Ch. 19: are we happier in modernity? It's doubtful."],
    blurb: "History with a sociological bent, with special attention paid to human happiness."
  )
  goatsong = item_data(
    rating: 5,
    author: "Tom Holt",
    title: "Goatsong: A Novel of Ancient Athens",
    series: [{ name: "The Walled Orchard",
               volume: 1 }],
    variants:    [{ format: :print,
                    isbn: "0312038380",
                    length: 247 }],
    experiences: [{ spans: [{ dates: "2019/05/28".."2019/06/13" }] },
                  { spans: [{ dates: "2020/05/01".."2020/05/23" }] },
                  { spans: [{ dates: "2021/08/17".. }],
                    progress: 0.5 }],
    visibility: 3,
    genres: ["historical fiction"],
    # history: [{ dates: Date.parse("2019-05-01"), amount: 31 },
    #           { dates: Date.parse("2019-05-02"), amount: 23 },
    #           { dates: Date.parse("2019-05-06")..Date.parse("2019-05-15"), amount: 10 },
    #           { dates: Date.parse("2019-05-20"), amount: 46 },
    #           { dates: Date.parse("2019-05-21"), amount: 47 }]
  )
  @items[:examples][:"in progress"] = [sapiens, goatsong]

  insula = item_data(
    rating: 4,
    author: "Robert Louis Stevenson",
    title: "Insula Thesauraria",
    series: [{ name: "Mount Hope Classics" }],
    variants:    [{ format: :print,
                    isbn: "1533694567",
                    length: "8:18",
                    extra_info: ["trans. Arcadius Avellanus", "unabridged"] }],
    experiences: [{ spans: [{ dates: "2020/10/20".."2021/08/31" }],
                    group: "weekly Latin reading with Sean and Dennis" }],
    genres: %w[latin novel],
    public_notes: ["Paper on Avellanus by Patrick Owens: https://linguae.weebly.com/arcadius-avellanus.html", "Arcadius Avellanus: Erasmus Redivivus (1947): https://ur.booksc.eu/book/18873920/05190d"]
  )
  cat_mojo = item_data(
    rating: 2,
    title: "Total Cat Mojo",
    variants:    [{ format: :audiobook,
                    sources: [{ name: "gift from neighbor Edith" }],
                    isbn: "B01NCYY3BV",
                    length: "10:13" }],
    experiences: [{ spans: [{ dates: "2020/03/21".."2020/04/01" }],
                    progress: 0.5 },
                  { spans: [{ dates: "2021/08/06".."2021/08/11" }],
                    progress: "4:45" }],
    visibility: 2,
    genres: %w[cats],
    public_notes: ["I would've felt bad if I hadn't tried."]
  )
  podcast_1 = item_data(
    rating: 1,
    title: "FiveThirtyEight Politics",
    variants:    [{ format: :audio,
                    length: "0:30" }],
    experiences: [{ spans: [{ dates: "2021/08/02".."2021/08/02" }],
                    progress: 0,
                    variant_index: 0 }],
    visibility: 1,
    genres: %w[politics podcast],
    public_notes: ["Not very deep. Disappointing."]
  )
  podcast_2 = podcast_1.merge(title: "The NPR Politics Podcast")
  podcast_3 = podcast_1.merge(title: "Pod Save America")
  what_if = item_data(
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
    experiences: [{ spans: [{ dates: "2021/08/01".."2021/08/15" }],
                    variant_index: 0 },
                  { spans: [{ dates: "2021/08/16".."2021/08/28" }],
                    group: "with Sam",
                    variant_index: 1 },
                  { spans: [{ dates: "2021/09/01".."2021/09/10" }],
                    variant_index: 0 }],
    visibility: 3,
    genres: %w[science],
    public_notes: ["Favorites: Global Windstorm, Relativistic Baseball, Laser Pointer, Hair Dryer, Machine-Gun Jetpack, Neutron Bullet."],
    blurb: "It's been a long time since I gave highest marks to a \"just for fun\" book, but wow, this was fun. So fun that after listening to the audiobook, I immediately proceeded to read the book, for its illustrations. If I'd read this as a kid, I might have been inspired to become a scientist."
  )
  @items[:examples][:"done"] = [insula, cat_mojo, podcast_1, podcast_2, podcast_3, what_if]


  nero = item_data(
    author: "Tom Holt",
    title: "A Song for Nero",
    variants:    [{ format: :ebook,
                    isbn: "B00GW4U2TM",
                    length: 580 }],
    genres: ["historical fiction"]
  )
  how_to = item_data(
    author: "Randall Munroe",
    title: "How To",
    variants:    [{ format: :print,
                    sources: [{ name: "Lexpub" }],
                    isbn: "B07NCQTJV3",
                    length: 320 }],
    experiences: [{ date_added: "2021/06/27" }],
    genres: %w[science]
  )
  @items[:examples][:"planned"] = [nero, how_to]

  nero = item_data(
    author: "Tom Holt",
    title: "A Song for Nero",
    variants:  [{ format: :ebook }],
    genres: ["historical fiction"]
  )
  true_grit = item_data(
    title: "True Grit",
    variants:  [{ format: :audiobook,
                  sources: [{ name: "Little Library" },
                            { name: "Hoopla" }] }],
    genres: ["historical fiction"]
  )
  lebowski = item_data(
    title: "Two Gentlemen of Lebowski",
    variants:  [{ format: :audiobook,
                  sources: [{ name: config.deep_fetch(:item, :sources, :default_name_for_url),
                              url: "https://www.runleiarun.com/lebowski" }] }],
    genres: ["historical fiction"]
  )
  how_to = item_data(
    author: "Randall Munroe",
    title: "How To",
    variants:  [{ format: :print,
                  sources: [{ name: "Lexpub" }] },
                { format: :ebook,
                  sources: [{ name: "Lexpub" },
                            { name: "Hoopla" }] },
                { format: :audiobook,
                  sources: [{ name: "Hoopla" },
                            { name: "Jeffco" }] }],
    genres: %w[science]
  )
  weird_earth = item_data(
    title: "Weird Earth",
    variants:  [{ format: :audiobook,
                  sources: [{ name: "Hoopla" },
                            { name: "Lexpub" }] },
                { format: :print,
                  sources: [{ name: "Lexpub" }] },
                { format: :ebook,
                  sources: [{ name: "Lexpub" }] }],
    genres: %w[science]
  )
  @items[:examples][:"compact planned"] = [nero, true_grit, lebowski, how_to, weird_earth]



  ### UTILITY METHODS

  NO_COLUMNS = config.deep_fetch(:csv, :columns).keys.map { |col| [col, false] }.to_h

  def set_columns(*columns, custom_numeric_columns: nil, custom_text_columns: nil)
    if columns.empty? || columns.first == :all
      this_config = config
    else
      this_columns = { columns: NO_COLUMNS.merge(columns.map { |col| [col, true] }.to_h) }
      this_config = config.merge(csv: config[:csv].merge(this_columns))
    end

    unless custom_numeric_columns.nil?
      this_config.deep_merge!(csv: { custom_numeric_columns: })
    end
    unless custom_text_columns.nil?
      this_config.deep_merge!(csv: { custom_text_columns: })
    end

    @csv = Reading::CSV.new(this_config)
  end

  # Removes any blank hashes in arrays, i.e. any that are the same as in the
  # template in config. Data in items must already be complete, i.e. merged with
  # the item template in config.
  def tidy(items)
    items.map { |data|
      without_blank_hashes(data)
    }
  end

  def without_blank_hashes(item_data)
    template = config.deep_fetch(:item, :template)
    %i[series variants experiences].each do |attribute|
      item_data[attribute] =
        item_data[attribute].reject { |value| value == template[attribute].first }
    end
    # Same for inner hash array at [:variants][:sources].
    item_data[:variants].each do |variant|
      variant[:sources] =
        variant[:sources].reject { |value| value == template.deep_fetch(:variants, 0, :sources).first }
    end
    # Same for inner hash array at [:experiences][:spans].
    item_data[:experiences].each do |variant|
      variant[:spans] =
        variant[:spans].reject { |value| value == template.deep_fetch(:experiences, 0, :spans).first }
    end
    item_data
  end

  def with_reread(data, date_started, date_finished, **other_attributes)
    data.dup.then { |dup|
      new_experience = dup[:experiences].first.merge(date_started:, date_finished:)
      other_attributes.each do |attribute, value|
        new_experience[attribute] = value
      end
      dup[:experiences] += [new_experience]
      dup
    }
  end

  def parse(string)
    @csv.parse(StringIO.new(string))
  end



  ### THE ACTUAL TESTS

  ## TESTS: ENABLING COLUMNS
  files[:enabled_columns].each do |set_name, file_str|
    columns = set_name.to_s.split(", ").map(&:to_sym)
    define_method "test_enabled_columns_#{columns.join("_")}" do
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
      define_method "test_#{columns_sym}_feature_#{feat}" do
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
    define_method "test_example_#{set_name}" do
      set_columns(:all)
      exp = tidy(items[:examples][set_name])
      act = parse(file_str)
      # debugger unless exp == act
      assert_equal exp, act,
        "Failed to parse this set of examples: #{set_name}"
    end
  end
end
