require_relative "../test_helper"

require_relative "../../lib/reading/util/blank"

# Same as the ActiveSupport blank test, but excludes UTF-16 encoding.
# https://github.com/rails/rails/blob/main/activesupport/test/core_ext/object/blank_test.rb
class BlankTest < Minitest::Test
  class EmptyTrue
    def empty?
      0
    end
  end

  class EmptyFalse
    def empty?
      nil
    end
  end

  BLANK = [ EmptyTrue.new, nil, false, "", "   ", "  \n\t  \r ", "　", "\u00a0", [], {}]
  NOT = [ EmptyFalse.new, Object.new, true, 0, 1, "a", [nil], { nil => 0 }, Time.now]

  def test_blank
    BLANK.each { |v| assert_equal true, v.blank?,  "#{v.inspect} should be blank" }
    NOT.each   { |v| assert_equal false, v.blank?, "#{v.inspect} should not be blank" }
  end

  def test_present
    BLANK.each { |v| assert_equal false, v.present?, "#{v.inspect} should not be present" }
    NOT.each   { |v| assert_equal true, v.present?,  "#{v.inspect} should be present" }
  end

  def test_presence
    BLANK.each { |v| assert_nil v.presence, "#{v.inspect}.presence should return nil" }
    NOT.each   { |v| assert_equal v,   v.presence, "#{v.inspect}.presence should return self" }
  end
end
