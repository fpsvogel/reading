require_relative "../test_helper"

require_relative "../../lib/reading/util/hash_to_struct"

class StringRemoveTest < Minitest::Test
  using Reading::Util::HashToStruct

  def test_simple_hash
    hash = { name: "Xan", origin: "Alpha Centauri" }
    struct = hash.to_struct

    assert_equal hash, struct.to_h
  end

  def test_nested_hash
    hash = {
      name: "Xan",
      origin: "Alpha Centauri",
      partner: { name: "Sam", origin: "Sol" },
    }
    struct = hash.to_struct

    struct_to_h = struct.to_h
    struct_to_h[:partner] = struct_to_h[:partner].to_h

    assert_equal hash, struct_to_h
  end

  def test_nested_array_of_hashes
    hash = {
      name: "Xan",
      origin: "Alpha Centauri",
      partners: [{ name: "Sam", origin: "Sol" }, { name: "J", origin: "Sol" }],
    }
    struct = hash.to_struct

    struct_to_h = struct.to_h
    struct_to_h[:partners] = struct_to_h[:partners].map(&:to_h)

    assert_equal hash, struct_to_h
  end
end
