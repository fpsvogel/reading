require_relative "test_helpers/test_helper"

require "reading/config"

class ParseTest < Minitest::Test
  def test_singleton
    Reading::Config.build(pages_per_hour: 10)
    hash = Reading::Config.new(pages_per_hour: 10).hash

    assert_equal Reading::Config.hash, hash

    Reading::Config.build # reset config to default
  end

  def test_blank_custom_config_results_in_default_config
    config = Reading::Config.new
    default_config = config.send(:default_config).merge(regex: config.send(:regex_config))

    assert_equal default_config, config.hash
  end

  def test_custom_config_is_deep_merged_with_default_config
    custom_comment_char = "#"
    custom_enabled_columns = [:head, :end_dates]
    extra_name_from_urls = { "gutenberg.org" => "Project Gutenberg" }

    config = Reading::Config.new(
      comment_character: custom_comment_char,
      enabled_columns: custom_enabled_columns,
      source_names_from_urls: extra_name_from_urls,
    )
    default_config = config.send(:default_config).merge(regex: config.send(:regex_config))
    default_config[:comment_character] = custom_comment_char
    default_config[:enabled_columns]= custom_enabled_columns
    default_config[:source_names_from_urls].merge!(extra_name_from_urls)

    assert_equal default_config, config.hash
  end

  def test_custom_formats_replace_default_formats
    custom_formats = {
      videogame: "🎮",
      tabletop:  "🎲",
    }

    config = Reading::Config.new(formats: custom_formats)

    assert_equal custom_formats, config.hash[:formats]
  end

  def test_enabled_columns_include_head_by_default
    config = Reading::Config.new(enabled_columns: [])

    assert_equal [:head], config.hash[:enabled_columns]
  end

  def test_nonexistent_enabled_columns_raise_error
    custom_enabled_columns = [:sources, :lol_nonexistent]

    assert_raises Reading::ConfigError do
      Reading::Config.new(enabled_columns: custom_enabled_columns)
    end
  end

  def test_formats_regexes_include_custom_formats
    custom_formats = {
      videogame: "🎮",
      tabletop:  "🎲",
    }

    config = Reading::Config.new(formats: custom_formats)

    assert_includes config.hash[:regex][:formats].to_s, custom_formats[:videogame]
    assert_includes config.hash[:regex][:formats].to_s, custom_formats[:tabletop]
    assert_includes config.hash[:regex][:formats_split].to_s, custom_formats[:videogame]
    assert_includes config.hash[:regex][:formats_split].to_s, custom_formats[:tabletop]
  end
end
