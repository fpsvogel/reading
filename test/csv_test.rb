$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require_relative "test_helper"

require "reading/parsing/csv"
require "tempfile"

class CSVTest < Minitest::Test
  def test_path_or_stream_required
    assert_raises ArgumentError do
      csv = Reading::Parsing::CSV.new
    end
  end

  def test_stream_must_respond_to_each_line
    assert_raises ArgumentError do
      csv = Reading::Parsing::CSV.new(stream: 1234)
    end
  end

  def test_file_at_path_must_exist
    assert_raises Reading::FileError do
      csv = Reading::Parsing::CSV.new('~/some/surely/nonexistent/path/reading.csv')
    end
  end

  def test_path_must_not_be_a_directory
    assert_raises Reading::FileError do
      csv = Reading::Parsing::CSV.new('~/')
    end
  end

  def test_if_stream_and_path_given_then_use_stream
    file = Tempfile.new('|Goatsong')
    string = '|Sapiens'
    items = Reading::Parsing::CSV.new(file.path, stream: string).parse

    assert_equal 1, items.count
    assert_equal "Sapiens", items.first.title
  end
end
