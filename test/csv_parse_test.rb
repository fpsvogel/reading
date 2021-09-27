# frozen_string_literal: true

require_relative "test_helper"
require_relative "test_base"

require "reading/csv/config"
require "reading/csv/parse"

class CsvParseTest < TestBase
  using Reading::Util::DeeperMerge

  @config = Reading.config
  @config[:error][:handle_error] = lambda do |error|
    @error_log << error
    puts error
  end

  # the hash keys inside :enabled_columns each are composed of a list of columns
  # to be enabled for each assertion in the columns test.
  @files = {}
  @files[:enabled_columns] = {}
  @files[:enabled_columns][:"name"] = <<~EOM.freeze
    \\Author - Title
    Sapiens
    Goatsong
    How To
  EOM
  @files[:enabled_columns][:"name, dates_finished"] = <<~EOM.freeze
    \\Author - Title|Dates finished
    Sapiens
    Goatsong|2020/5/30
    How To
  EOM
  @files[:enabled_columns][:"name, dates_started"] = <<~EOM.freeze
    Sapiens|2021/9/1
    Goatsong|2020/5/1
    How To
  EOM
  @files[:enabled_columns][:"name, dates_started, dates_finished"] = <<~EOM.freeze
    Sapiens|2021/9/1
    Goatsong|2020/5/1|2020/5/30
    How To
  EOM
  @files[:enabled_columns][:"rating, name, dates_started, dates_finished"] = <<~EOM.freeze
    |Sapiens|2021/9/1
    5|Goatsong|2020/5/1|2020/5/30
    |How To
  EOM
  # length but no sources
  @files[:enabled_columns][:"rating, name, dates_started, dates_finished, length"] = <<~EOM.freeze
    |Sapiens|2021/9/1||15:17
    5|Goatsong|2020/5/1|2020/5/30|247
    |How To
  EOM
  # sources but no length
  @files[:enabled_columns][:"rating, name, sources, dates_started, dates_finished"] = <<~EOM.freeze
    |Sapiens|Vail Library B00ICN066A|2021/9/1
    5|Goatsong|0312038380|2020/5/1|2020/5/30
    |How To
  EOM
  # sources and length
  @files[:enabled_columns][:"rating, name, sources, dates_started, dates_finished, length"] = <<~EOM.freeze
    |Sapiens|Vail Library B00ICN066A|2021/9/1||15:17
    5|Goatsong|0312038380|2020/5/1|2020/5/30|247
    |How To
  EOM



  @files[:custom_columns] = {}
  @files[:custom_columns][:number] = <<~EOM.freeze
    \\Rating|Name|Sources|Dates started|Dates finished|Length|Surprise factor|Family friendliness
    |Sapiens|Vail Library B00ICN066A|2021/9/1||15:17|6|3.9
    5|Goatsong|0312038380|2020/5/1|2020/5/30|247|9
    |How To
  EOM
  @files[:custom_columns][:text] = <<~EOM.freeze
    \\Rating|Name|Sources|Dates started|Dates finished|Length|Mood|Color
    |Sapiens|Vail Library B00ICN066A|2021/9/1||15:17|apprehensive|blue
    5|Goatsong|0312038380|2020/5/1|2020/5/30|247|tragicomic
    |How To
  EOM



  # for the rest of the hashes in @files, their key specifies which single
  # column is to be enabled. that makes a config unnecessary such as this:
  # @column_configs[:name] = NO_COLUMNS # Name column is enabled automatically.
  @files[:name] =
  {
  author:
    "Tom Holt - Goatsong",
  series:
    "Tom Holt - Goatsong -- in The Walled Orchard",
  series_with_volume:
    "Tom Holt - Goatsong -- The Walled Orchard, #1",
  extra_info:
    "Tom Holt - Goatsong -- unabridged -- 1990",
  extra_info_and_series:
    "Tom Holt - Goatsong -- unabridged -- The Walled Orchard, #1 -- 1990",
  format:
    "📕Tom Holt - Goatsong",
  multi_items:
    "📕Tom Holt - Goatsong, 🔊Sapiens",
  progress:
    "50% Goatsong",
  progress_pages:
    "p220 Goatsong",
  progress_pages_without_p:
    "220 Goatsong",
  progress_time:
    "2:30 Goatsong",
  dnf:
    "DNF Goatsong",
  dnf_with_progress:
    "DNF 50% Goatsong",
  dnf_with_multi_items:
    "DNF 📕Tom Holt - Goatsong, 🔊Sapiens",
  all_features:
    "DNF 50% 📕Tom Holt - Goatsong -- unabridged -- The Walled Orchard, #1 -- 1990, 🔊Sapiens"
  }

  @files[:sources] =
  {
  isbn10:
    "Goatsong|0312038380",
  isbn13:
    "Goatsong|978-0312038380",
  ASIN:
    "Goatsong|B00GVG01HE",
  source:
    "Goatsong|Little Library",
  url_source:
    "Goatsong|https://www.edlin.org/holt",
  url_source_with_name:
    "Goatsong|about the author - https://www.edlin.org/holt",
  url_source_with_name_after:
    "Goatsong|https://www.edlin.org/holt - about the author",
  sources:
    "Goatsong|Little Library https://www.edlin.org/holt Lexpub",
  sources_commas:
    "Goatsong|Little Library, https://www.edlin.org/holt - about the author, Lexpub",
  source_with_isbn:
    "Goatsong|Little Library 0312038380",
  source_with_isbn_reversed:
    "Goatsong|0312038380 Little Library",
  sources_with_isbn:
    "Goatsong|Little Library 0312038380 https://www.edlin.org/holt",
  sources_with_isbn_commas:
    "Goatsong|Little Library, 0312038380, https://www.edlin.org/holt - about the author, Lexpub",
  simple_variants:
    "Goatsong|Little Library -- Lexpub",
  extra_info_can_be_included_if_format_is_specified:
    "Goatsong|📕Little Library -- unabridged -- 1990",
  formats_can_delimit_variants:
    "Goatsong|📕Little Library -- unabridged -- 1990 🔊Lexpub",
  length_after_sources_isbn_and_before_extra_info:
    "Goatsong|📕Little Library 0312038380 247 -- unabridged -- 1990 🔊Lexpub 7:03",
  multiple_sources_allowed_in_variant:
    "Goatsong|📕Little Library, 0312038380, https://www.edlin.org/holt - about the author, Lexpub, 247 -- unabridged -- 1990 🔊Lexpub 7:03",
  }

  @files[:dates_started] =
  {
  date_started:
    "Sapiens|2020/09/01",
  date_added:
    "Sapiens|2019/08/20 >",
  date_added_and_started:
    "Sapiens|2019/08/20 > 2020/09/01",
  dates_started:
    "Sapiens|2020/09/01, 2021/07/15",
  dates_added_and_started:
    "Sapiens|2019/08/20 > 2020/09/01, 2021/07/15, 2021/09/20 >",
  progress:
    "Sapiens|50% 2020/09/01",
  progress_must_be_at_the_beginning_or_immediately_after_date_started_separator:
    "Sapiens|2019/08/20 > 50% 2020/09/01, 50% 2021/01/01 > 2021/07/15",
  progress_pages:
    "Sapiens|220p 2020/09/01",
  progress_pages_without_p:
    "Sapiens|220 2020/09/01",
  progress_time:
    "Sapiens|2:30 2020/09/01",
  dnf:
    "Sapiens|DNF 2020/09/01",
  dnf_with_progress:
    "Sapiens|DNF 50% 2020/09/01",
  variant:
    "Sapiens|2020/09/01 v2",
  variant_with_just_date_added:
    "Sapiens|2019/08/20 > v2",
  variant_can_be_anywhere:
    "Sapiens|2019/08/20 v2 >, v3 2021/07/15",
  group_can_be_indicated_at_the_very_end:
    "Sapiens|2020/09/01 v2 🤝🏼 county book club",
  group_can_be_without_text:
    "Sapiens|2020/09/01 v2 🤝🏼",
  other_text_before_or_after_dates_is_ignored:
    "Sapiens|found on Chirp on 2019/08/20 and recommended by Jo > instantly hooked 2020/09/01 at the beach",
  all_features:
    "Sapiens|found on Chirp on 2019/08/20 and recommended by Jo > DNF 50% instantly hooked 2020/09/01 at the beach v2, 2:30 2021/07/15, 2021/09/20 > v3",
  }

  @files[:genres] =
  {
  genres:
    "Goatsong|novel, history",
  visibility:
    "Goatsong|novel, history, for starred friends",
  visibility_anywhere:
    "Goatsong|novel, for starred friends, history",
  visibility_alt:
    "Goatsong|novel, to-starred, history",
  }

  # realistic examples from the reading.csv template in Plain Reading.
  @files[:examples] = {}
  @files[:examples][:in_progress] = <<~EOM.freeze
    \\Rating|Format, Author, Title|Sources, ISBN/ASIN|Dates added > Started, Progress|Dates finished|Genres|Length|Public notes|Blurb|Private notes|History
    \\------ IN PROGRESS
    |🔊Sapiens: A Brief History of Humankind|Vail Library B00ICN066A|2021/06/11 > 2021/09/20| |history, wisdom|15:17|Ch. 5: "We did not domesticate wheat. It domesticated us." -- End of ch. 8: the ubiquity of patriarchal societies is so far unexplained. It would make more sense for women (being on average more socially adept) to have formed a matriarchal society as among the bonobos. -- Ch. 19: are we happier in modernity? It's doubtful.|History with a sociological bent, with special attention paid to human happiness.
    5|50% 📕Tom Holt - Goatsong: A Novel of Ancient Athens -- The Walled Orchard, #1|0312038380|2019/05/28, 2020/05/01, 2021/08/17|2019/06/13, 2020/05/23|historical fiction|247||||2019/5/1 p31, 5/2 p54, 5/6-15 10p, 5/20 p200, 5/21 done
  EOM
  @files[:examples][:done] = <<~EOM.freeze
    \\------ DONE
    4|📕Robert Louis Stevenson - Insula Thesauraria -- in Mount Hope Classics -- trans. Arcadius Avellanus -- unabridged|1533694567|2020/10/20 🤝🏼 weekly Latin reading with Sean and Dennis|2021/08/31|latin, novel|8:18|Paper on Avellanus by Patrick Owens: https://linguae.weebly.com/arcadius-avellanus.html -- Arcadius Avellanus: Erasmus Redivivus (1947): https://ur.booksc.eu/book/18873920/05190d
    2|🔊Total Cat Mojo|gift from neighbor Edith B01NCYY3BV|DNF 50% 2020/03/21, DNF 4:45 2021/08/06|2020/04/01, 2021/08/11|cats, for friends|10:13|I would've felt bad if I hadn't tried.
    1|DNF 🎤FiveThirtyEight Politics 🎤The NPR Politics Podcast 🎤Pod Save America| |2021/08/02|2021/08/02|politics, podcast, for starred friends|0:30|Not very deep. Disappointing.
    5|Randall Munroe - What If?: Serious Scientific Answers to Absurd Hypothetical Questions|🔊Lexpub B00LV2F1ZA 6:36 -- unabridged -- published 2016 ⚡Amazon B00IYUYF4A 320 -- published 2014|2021/08/01, 2021/08/16 v2 🤝🏼 with Sam, 2021/09/01|2021/08/15, 2021/08/28, 2021/09/10|science| |Favorites: Global Windstorm, Relativistic Baseball, Laser Pointer, Hair Dryer, Machine-Gun Jetpack, Neutron Bullet.|It's been a long time since I gave highest marks to a "just for fun" book, but wow, this was fun. So fun that after listening to the audiobook, I immediately proceeded to read the book, for its illustrations. If I'd read this as a kid, I might have been inspired to become a scientist.
  EOM
  @files[:examples][:planned] = <<~EOM.freeze
    \\------ PLANNED
    |⚡Tom Holt - A Song for Nero|B00GW4U2TM| | |historical fiction|580
    |📕Randall Munroe - How To: Absurd Scientific Advice for Common Real-World Problems|Lexpub B07NCQTJV3|2021/06/27 >| |science|320
  EOM
  @files[:examples][:compact_planned] = <<~EOM.freeze
    \\------ PLANNED
    \\HISTORICAL FICTION: ⚡Tom Holt - A Song for Nero, 🔊True Grit @Little Library, @Hoopla, 🔊Two Gentlemen of Lebowski @Lexpub
    \\SCIENCE: 📕Randall Munroe - How To: Absurd Scientific Advice for Common Real-World Problems @Lexpub, 🔊On the Origin of Species, 🔊Weird Earth @Hoopla
  EOM

  def self.item_data(**partial_data)
    # this merge is not the same as Reading::Util::DeeperMerge. this one uses an
    # array value's first hash as the template for all corresponding partial
    # data, for example in :variants and :experiences in the item template.
    config[:item][:template].merge(partial_data) do |key, old_value, new_value|
      if old_value.is_a?(Array) && old_value.first.is_a?(Hash)
        template = old_value.first
        new_value.map { |v| template.merge(v) }
      else
        new_value
      end
    end
  end

  def with_reread(data, started, finished, **other_attributes)
    data.dup.then do |dup|
      new_experience = dup[:experiences].first.merge(date_started: started, date_finished: finished)
      other_attributes.each do |attribute, value|
        new_experience[attribute] = value
      end
      dup[:experiences] += [new_experience]
      dup
    end
  end

  @items = {}
  @items[:enabled_columns] = []
  a = item_data(title: "Sapiens")
  b = item_data(title: "Goatsong")
  c = item_data(title: "How To")
  @items[:enabled_columns] << [a, b, c]

  b_finished_inner = { experiences: [{ date_finished: "2020/5/30" }] }
  b_finished = b.deeper_merge(b_finished_inner)
  @items[:enabled_columns] << [a, b_finished, c]

  a_started = a.deeper_merge(experiences: [{ date_started: "2021/9/1" }])
  b_started = b.deeper_merge(experiences: [{ date_started: "2020/5/1" }])
  @items[:enabled_columns] << [a_started, b_started, c]

  a = a_started
  b = b_started.deeper_merge(b_finished_inner)
  @items[:enabled_columns] << [a, b, c]

  a = a.merge(rating: nil)
  b = b.merge(rating: 5)
  @items[:enabled_columns] << [a, b, c]

  a_length = a.deeper_merge(variants: [{ length: "15:17" }])
  b_length = b.deeper_merge(variants: [{ length: 247 }])
  @items[:enabled_columns] << [a_length, b_length, c]

  a_sources = a.deeper_merge(variants: [{ isbn: "B00ICN066A",
                           sources: [["Vail Library"]] }])
  b_sources = b.deeper_merge(variants: [{ isbn: "0312038380" }])
  @items[:enabled_columns] << [a_sources, b_sources, c]

  a = a_sources.deeper_merge(variants: [{ length: "15:17" }])
  b = b_sources.deeper_merge(variants: [{ length: 247 }])
  @items[:enabled_columns] << [a, b, c]



  @items[:custom_columns] = {}
  a_custom_number = a.merge(surprise_factor: 6,
                            family_friendliness: 3.9)
  b_custom_number = b.merge(surprise_factor: 9,
                            family_friendliness: nil)
  c_custom_number = c.merge(surprise_factor: nil,
                            family_friendliness: nil)
  @items[:custom_columns][:number] = [a_custom_number, b_custom_number, c_custom_number]

  a_custom_text = a.merge(mood: "apprehensive",
                          color: "blue")
  b_custom_text = b.merge(mood: "tragicomic",
                          color: nil)
  c_custom_text = c.merge(mood: nil,
                          color: nil)
  @items[:custom_columns][:text] = [a_custom_text, b_custom_text, c_custom_text]



  @items[:name] = {}
  a_basic = item_data(author: "Tom Holt", title: "Goatsong")
  @items[:name][:author] = [a_basic]

  a = a_basic.deeper_merge(series: [{ name: "The Walled Orchard" }])
  @items[:name][:series] = [a]

  a = a.deeper_merge(series: [{ volume: 1 }])
  series_with_volume = a.slice(:series)
  @items[:name][:series_with_volume] = [a]

  extra_info = %w[unabridged 1990]
  variants_with_extra_info = { variants: [{ extra_info: extra_info }] }
  a = a_basic.deeper_merge(variants_with_extra_info)
  @items[:name][:extra_info] = [a]

  a = a.merge(series_with_volume)
  @items[:name][:extra_info_and_series] = [a]

  a_with_format = a_basic.deeper_merge(variants: [{ format: :print }])
  @items[:name][:format] = [a_with_format]

  b = item_data(title: "Sapiens", variants: [{ format: :audiobook }])
  @items[:name][:multi_items] = [a_with_format, b]

  half_progress = { experiences: [{ progress: 0.5 }] }
  a = item_data(title: "Goatsong", **half_progress)
  @items[:name][:progress] = [a]

  a = item_data(title: "Goatsong", experiences: [{ progress: 220 }])
  @items[:name][:progress_pages] = [a]

  @items[:name][:progress_pages_without_p] = [a]

  a = item_data(title: "Goatsong", experiences: [{ progress: "2:30" }])
  @items[:name][:progress_time] = [a]

  a = item_data(title: "Goatsong", experiences: [{ progress: 0 }])
  @items[:name][:dnf] = [a]

  a = item_data(title: "Goatsong", experiences: [{ progress: 0.5 }])
  @items[:name][:dnf_with_progress] = [a]

  a = a_with_format.deeper_merge(experiences: [{ progress: 0 }])
  b = b.deeper_merge(experiences: [{ progress: 0 }])
  @items[:name][:dnf_with_multi_items] = [a, b]

  a = a.merge(series_with_volume).deeper_merge(variants_with_extra_info).deeper_merge(half_progress)
  b = b.deeper_merge(half_progress)
  @items[:name][:all_features] = [a, b]



  @items[:sources] = {}
  title = "Goatsong"
  a_basic = item_data(title: title)
  isbn = "0312038380"
  a = a_basic.deeper_merge(variants: [{ isbn: isbn }])
  @items[:sources][:isbn10] = [a]

  a = a_basic.deeper_merge(variants: [{ isbn: "978-0312038380" }])
  @items[:sources][:isbn13] = [a]

  a = a_basic.deeper_merge(variants: [{ isbn: "B00GVG01HE" }])
  @items[:sources][:ASIN] = [a]

  library = ["Little Library"]
  a = a_basic.deeper_merge(variants: [{ sources: [library] }])
  @items[:sources][:source] = [a]

  site = ["https://www.edlin.org/holt"]
  a = a_basic.deeper_merge(variants: [{ sources: [site] }])
  @items[:sources][:url_source] = [a]

  site_named = ["https://www.edlin.org/holt", "about the author"]
  a = a_basic.deeper_merge(variants: [{ sources: [site_named.reverse] }])
  @items[:sources][:url_source_with_name] = [a]

  a = a_basic.deeper_merge(variants: [{ sources: [site_named] }])
  @items[:sources][:url_source_with_name_after] = [a]

  lexpub = ["Lexpub"]
  three_sources = [site, library, lexpub]
  a = a_basic.deeper_merge(variants: [{ sources: three_sources }])
  @items[:sources][:sources] = [a]

  three_sources_with_name = [site_named, library, lexpub]
  a = a_basic.deeper_merge(variants: [{ sources: three_sources_with_name }])
  @items[:sources][:sources_commas] = [a]

  a = a_basic.deeper_merge(variants: [{ sources: [library],
                                      isbn: isbn }])
  @items[:sources][:source_with_isbn] = [a]

  @items[:sources][:source_with_isbn_reversed] = [a]

  a = a_basic.deeper_merge(variants: [{ sources: [site, library],
                                      isbn: isbn }])
  @items[:sources][:sources_with_isbn] = [a]

  a = a_basic.deeper_merge(variants: [{ sources: three_sources_with_name,
                                      isbn: isbn }])
  @items[:sources][:sources_with_isbn_commas] = [a]

  a = item_data(title: title,
                variants: [{ sources: [library] },
                           { sources: [lexpub] }])
  @items[:sources][:simple_variants] = [a]

  a = item_data(title: title,
                variants: [{ format: :print,
                             sources: [library],
                             extra_info: extra_info }])
  @items[:sources][:extra_info_can_be_included_if_format_is_specified] = [a]

  a = item_data(title: title,
                variants: [a[:variants].first,
                              { format: :audiobook,
                                sources: [lexpub] }])
  @items[:sources][:formats_can_delimit_variants] = [a]

  a = item_data(title: title,
                variants: [a[:variants].first.merge(isbn: isbn, length: 247),
                           a[:variants].last.merge(length: "7:03")])
  @items[:sources][:length_after_sources_isbn_and_before_extra_info] = [a]

  a = item_data(title: title,
                variants: [a[:variants].first.merge(sources: three_sources_with_name),
                           a[:variants].last])
  @items[:sources][:multiple_sources_allowed_in_variant] = [a]



  @items[:dates_started] = {}
  a_basic = item_data(title: "Sapiens")
  exp_started = { experiences: [{ date_started: "2020/09/01" }] }
  a_started = a_basic.deeper_merge(exp_started)
  @items[:dates_started][:date_started] = [a_started]

  exp_added = { experiences: [{ date_added: "2019/08/20" }] }
  a = a_basic.deeper_merge(exp_added)
  @items[:dates_started][:date_added] = [a]

  a_added_started = a_basic.deeper_merge(exp_added.deeper_merge(exp_started))
  @items[:dates_started][:date_added_and_started] = [a_added_started]

  exp_second_started = { experiences: [{},
                                       { date_started: "2021/07/15" }] }
  a = item_data(**a_basic.deeper_merge(exp_started).deeper_merge(exp_second_started))
  @items[:dates_started][:dates_started] = [a]

  exp_third_added = { experiences: [{},
                                    {},
                                    { date_added: "2021/09/20" }] }
  a_many = item_data(**a_basic.deeper_merge(exp_started).deeper_merge(exp_second_started)
                              .deeper_merge(exp_added).deeper_merge(exp_third_added))
  @items[:dates_started][:dates_added_and_started] = [a_many]

  exp_progress = ->(amount) { { experiences: [{ progress: amount }] } }
  a_halfway = a_started.deeper_merge(exp_progress.call(0.5))
  @items[:dates_started][:progress] = [a_halfway]

  exp_second_added = { experiences: [{},
                                     { date_added: "2021/01/01" }] }
  exp_two_progresses = { experiences: [{ progress: 0.5 },
                                       { progress: 0.5 }] }
  a = item_data(**a_basic.deeper_merge(exp_added).deeper_merge(exp_second_added)
                          .deeper_merge(exp_started).deeper_merge(exp_second_started)
                          .deeper_merge(exp_two_progresses))
  @items[:dates_started][:progress_must_be_at_the_beginning_or_immediately_after_date_started_separator] = [a]

  a = a_started.deeper_merge(exp_progress.call(220))
  @items[:dates_started][:progress_pages] = [a]

  @items[:dates_started][:progress_pages_without_p] = [a]

  a = a_started.deeper_merge(exp_progress.call("2:30"))
  @items[:dates_started][:progress_time] = [a]

  a = a_started.deeper_merge(exp_progress.call(0))
  @items[:dates_started][:dnf] = [a]

  @items[:dates_started][:dnf_with_progress] = [a_halfway]

  exp_v2 = { experiences: [{ variant_id: 1 }] }
  a_variant = a_started.deeper_merge(exp_v2)
  @items[:dates_started][:variant] = [a_variant]

  a = a_basic.deeper_merge(exp_added.deeper_merge(exp_v2))
  @items[:dates_started][:variant_with_just_date_added] = [a]

  exp_v3 = { experiences: [{},
                           { variant_id: 2 }] }
  a = item_data(**a.deeper_merge(exp_second_started).deeper_merge(exp_v3))
  @items[:dates_started][:variant_can_be_anywhere] = [a]

  a = a_variant.deeper_merge(experiences: [{ group: "county book club" }])
  @items[:dates_started][:group_can_be_indicated_at_the_very_end] = [a]

  a = a_variant.deeper_merge(experiences: [{ group: "" }])
  @items[:dates_started][:group_can_be_without_text] = [a]

  @items[:dates_started][:other_text_before_or_after_dates_is_ignored] = [a_added_started]

  a = a_many.deeper_merge(experiences: [{ progress: 0.5,
                                        variant_id: 1 },
                                      { progress: "2:30" },
                                      { variant_id: 2 }])
  @items[:dates_started][:all_features] = [a]



  @items[:genres] = {}
  a_basic = item_data(title: "Goatsong", genres: %w[novel history])
  @items[:genres][:genres] = [a_basic]

  a = a_basic.merge(visibility: 1)
  @items[:genres][:visibility] = [a]

  @items[:genres][:visibility_anywhere] = [a]

  @items[:genres][:visibility_alt] = [a]



  @items[:examples] = {}
  sapiens = item_data(
    title: "Sapiens: A Brief History of Humankind",
    variants:    [{ format: :audiobook,
                    sources: [["Vail Library"]],
                    isbn: "B00ICN066A",
                    length: "15:17" }],
    experiences: [{ date_added: "2021/06/11",
                    date_started:  "2021/09/20" }],
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
    experiences: [{ date_started: "2019/05/28",
                    date_finished: "2019/06/13" },
                  { date_started: "2020/05/01" ,
                    date_finished: "2020/05/23" },
                  { date_started: "2021/08/17",
                    progress: 0.5 }],
    visibility: 3,
    genres: ["historical fiction"],
    history: ["2019/5/1 p31, 5/2 p54, 5/6-15 10p, 5/20 p200, 5/21 done"]
  )
  @items[:examples][:in_progress] = [sapiens, goatsong]

  insula = item_data(
    rating: 4,
    author: "Robert Louis Stevenson",
    title: "Insula Thesauraria",
    series: [{ name: "Mount Hope Classics" }],
    variants:    [{ format: :print,
                    isbn: "1533694567",
                    length: "8:18",
                    extra_info: ["trans. Arcadius Avellanus", "unabridged"] }],
    experiences: [{ date_started: "2020/10/20",
                    date_finished: "2021/08/31",
                    group: "weekly Latin reading with Sean and Dennis" }],
    genres: %w[latin novel],
    public_notes: ["Paper on Avellanus by Patrick Owens: https://linguae.weebly.com/arcadius-avellanus.html", "Arcadius Avellanus: Erasmus Redivivus (1947): https://ur.booksc.eu/book/18873920/05190d"]
  )
  cat_mojo = item_data(
    rating: 2,
    title: "Total Cat Mojo",
    variants:    [{ format: :audiobook,
                    sources: [["gift from neighbor Edith"]],
                    isbn: "B01NCYY3BV",
                    length: "10:13" }],
    experiences: [{ date_started:  "2020/03/21",
                    date_finished: "2020/04/01",
                    progress: 0.5 },
                  { date_started:  "2021/08/06",
                    date_finished: "2021/08/11",
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
    experiences: [{ date_started:  "2021/08/02",
                    date_finished: "2021/08/02",
                    progress: 0,
                    variant_id: 0 }],
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
                    sources: [%w[Lexpub]],
                    isbn: "B00LV2F1ZA",
                    length: "6:36",
                    extra_info: ["unabridged", "published 2016"] },
                  { format: :ebook,
                    sources: [%w[Amazon]],
                    isbn: "B00IYUYF4A",
                    length: 320,
                    extra_info: ["published 2014"] }],
    experiences: [{ date_started:  "2021/08/01",
                    date_finished: "2021/08/15",
                    variant_id: 0 },
                  { date_started:  "2021/08/16",
                    date_finished: "2021/08/28",
                    group: "with Sam",
                    variant_id: 1 },
                  { date_started:  "2021/09/01",
                    date_finished: "2021/09/10",
                    variant_id: 0 }],
    visibility: 3,
    genres: %w[science],
    public_notes: ["Favorites: Global Windstorm, Relativistic Baseball, Laser Pointer, Hair Dryer, Machine-Gun Jetpack, Neutron Bullet."],
    blurb: "It's been a long time since I gave highest marks to a \"just for fun\" book, but wow, this was fun. So fun that after listening to the audiobook, I immediately proceeded to read the book, for its illustrations. If I'd read this as a kid, I might have been inspired to become a scientist."
  )
  @items[:examples][:done] = [insula, cat_mojo, podcast_1, podcast_2, podcast_3, what_if]


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
    title: "How To: Absurd Scientific Advice for Common Real-World Problems",
    variants:    [{ format: :print,
                    sources: [%w[Lexpub]],
                    isbn: "B07NCQTJV3",
                    length: 320 }],
    experiences: [{ date_added: "2021/06/27" }],
    genres: %w[science]
  )
  @items[:examples][:planned] = [nero, how_to]

  nero = item_data(
    author: "Tom Holt",
    title: "A Song for Nero",
    variants:  [{ format: :ebook }],
    genres: ["historical fiction"]
  )
  true_grit = item_data(
    title: "True Grit",
    variants:  [{ format: :audiobook,
                  sources: [["Little Library"], ["Hoopla"]] }],
    genres: ["historical fiction"]
  )
  lebowski = item_data(
    title: "Two Gentlemen of Lebowski",
    variants:  [{ format: :audiobook,
                  sources: [%w[Lexpub]] }],
    genres: ["historical fiction"]
  )
  how_to = item_data(
    author: "Randall Munroe",
    title: "How To: Absurd Scientific Advice for Common Real-World Problems",
    variants:  [{ format: :print,
                  sources: [%w[Lexpub]] }],
    genres: %w[science]
  )
  darwin = item_data(
    title: "On the Origin of Species",
    variants:  [{ format: :audiobook }],
    genres: %w[science]
  )
  weird_earth = item_data(
    title: "Weird Earth",
    variants:  [{ format: :audiobook,
                  sources: [%w[Hoopla]] }],
    genres: %w[science]
  )
  @items[:examples][:compact_planned] = [nero, true_grit, lebowski, how_to, darwin, weird_earth]



  # create files before all tests.
  @files.each do |group_name, hash|
    hash.each do |name, string|
      IO.write("#{group_name}_#{name}.csv", string)
    end
  end

  # then delete them afterward.
  Minitest.after_run do
    @files.each do |group_name, hash|
      hash.each do |name, string|
        File.delete("#{group_name}_#{name}.csv")
      end
    end
  end

  NO_COLUMNS = config.fetch(:csv).fetch(:columns).keys.map { |col| [col, false] }.to_h

  def set_columns(*columns, custom_columns: nil)
    if columns.empty? || columns.first == :all
      this_config = config
    else
      this_columns = { columns: NO_COLUMNS.merge(columns.map { |col| [col, true] }.to_h) }
      this_config = config.merge(csv: config.fetch(:csv).merge(this_columns))
    end
    unless custom_columns.nil?
      this_config = this_config.deeper_merge(csv: { custom_columns: custom_columns })
    end
    @parse = Reading::Csv::Parse.new(this_config)
  end

  def parse(path)
    @parse.call(path: path)
  rescue Errno::ENOENT
    raise Reading::FileError.new(path, label: "File not found!")
  end

  def test_columns_can_be_disabled
    # skip
    column_sets = files[:enabled_columns].keys
    column_sets.each_with_index do |set_name, i|
      columns = set_name.to_s.split(", ").map(&:to_sym)
      set_columns(*columns)
      exp = items[:enabled_columns][i]
      act = parse("enabled_columns_#{set_name}.csv")
      binding.pry unless exp == act
      assert_equal exp, act
    end
  end

  def test_number_custom_columns
    # skip
    set_columns(*%i[rating name sources dates_started dates_finished length],
                custom_columns: { surprise_factor: :number, family_friendliness: :number })
    exp = items[:custom_columns][:number]
    act = parse("custom_columns_number.csv")
    binding.pry unless exp == act
    assert_equal exp, act
  end

  def test_text_custom_columns
    # skip
    set_columns(*%i[rating name sources dates_started dates_finished length],
                custom_columns: { mood: :text, color: :text })
    exp = items[:custom_columns][:text]
    act = parse("custom_columns_text.csv")
    binding.pry unless exp == act
    assert_equal exp, act
  end

  def test_name_column_features
    # skip
    set_columns(:name)
    files[:name].each do |feat, _file_str|
      exp = items[:name][feat]
      act = parse("name_#{feat}.csv")
      binding.pry unless exp == act
      assert_equal exp, act
    end
  end

  def test_sources_column_features
    # skip
    set_columns(:sources)
    files[:sources].each do |feat, _file_str|
      exp = items[:sources][feat]
      act = parse("sources_#{feat}.csv")
      # binding.pry unless exp == act
      assert_equal exp, act
    end
  end

  def test_dates_started_column_features
    # skip
    set_columns(:dates_started)
    files[:dates_started].each do |feat, _file_str|
      exp = items[:dates_started][feat]
      act = parse("dates_started_#{feat}.csv")
      # binding.pry unless exp == act
      assert_equal exp, act
    end
  end

  def test_genres_column_features
    # skip
    set_columns(:genres)
    files[:genres].each do |feat, _file_str|
      exp = items[:genres][feat]
      act = parse("genres_#{feat}.csv")
      # binding.pry unless exp == act
      assert_equal exp, act
    end
  end

  def test_examples
    # skip
    set_columns(:all)
    files[:examples].each do |group, _file_str|
      exp = items[:examples][group]
      act = parse("examples_#{group}.csv")
      # binding.pry unless exp == act
      assert_equal exp, act
    end
  end
end
