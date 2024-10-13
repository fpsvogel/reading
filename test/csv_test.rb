require_relative "test_helpers/test_helper"

require "reading/parsing/csv"
require "tempfile"

class CSVTest < Minitest::Test
  def test_path_or_lines_required
    assert_raises ArgumentError do
      Reading::Parsing::CSV.new
    end
  end

  def test_lines_must_respond_to_each_line
    assert_raises ArgumentError do
      Reading::Parsing::CSV.new(lines: 1234)
    end
  end

  def test_file_at_path_must_exist
    assert_raises Reading::FileError do
      Reading::Parsing::CSV.new(path: "~/some/surely/nonexistent/path/reading.csv")
    end
  end

  def test_path_must_not_be_a_directory
    assert_raises Reading::FileError do
      Reading::Parsing::CSV.new(path: "~/")
    end
  end

  def test_if_lines_and_path_given_then_use_lines
    file = Tempfile.new("|Goatsong")
    string = "|Sapiens"
    items = Reading::Parsing::CSV.new(path: file.path, lines: string).parse

    assert_equal 1, items.count
    assert_equal "Sapiens", items.first.title
  end
end
