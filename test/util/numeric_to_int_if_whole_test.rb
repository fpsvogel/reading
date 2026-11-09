require_relative "../test_helpers/test_helper"

class NumericToIntIfWholeTest < Minitest::Test
  using Reading::Util::NumericToIntIfWhole

  def test_float_not_converted_if_not_whole
    float = 1.5

    assert_equal float, float.to_int_if_whole
  end

  def test_float_is_converted_if_whole
    float = 1.0
    converted = float.to_int_if_whole

    assert_equal float, converted
    assert_equal Integer, converted.class
  end

  def test_rational_number
    rational = 3/3r
    converted = rational.to_int_if_whole

    assert_equal rational, converted
    assert_equal Integer, converted.class
  end
end
