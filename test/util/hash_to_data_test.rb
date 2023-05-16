require_relative "../test_helpers/test_helper"

class HashToDataTest < Minitest::Test
  using Reading::Util::HashToData

  def test_simple_hash
    hash = { name: "Xan", origin: "Alpha Centauri" }
    data = hash.to_data

    assert_equal hash, data.to_h
  end

  def test_nested_hash
    hash = {
      name: "Xan",
      origin: "Alpha Centauri",
      partner: { name: "Sam", origin: "Sol" },
    }
    data = hash.to_data

    data_to_h = data.to_h
    data_to_h[:partner] = data_to_h[:partner].to_h

    assert_equal hash, data_to_h
  end

  def test_nested_array_of_hashes
    hash = {
      name: "Xan",
      origin: "Alpha Centauri",
      partners: [{ name: "Sam", origin: "Sol" }, { name: "J", origin: "Sol" }],
    }
    data = hash.to_data

    data_to_h = data.to_h
    data_to_h[:partners] = data_to_h[:partners].map(&:to_h)

    assert_equal hash, data_to_h
  end
end
