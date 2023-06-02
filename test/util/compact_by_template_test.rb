require_relative '../test_helpers/test_helper'

class CompactByTemplateTest < Minitest::Test
  using Reading::Util::HashCompactByTemplate

  # Cases where a hash IS compacted:

  def test_equal_array_of_hashes_is_compacted_when_one_element
    template =  { a: 1, b: [{ b1a: "one", b1b: "bar" }] }
    hash =      { a: 2, b: template[:b].dup }
    compacted = { a: 2, b: [] }

    assert_equal compacted, hash.compact_by(template:)
  end

  def test_compacted_template_has_arrays_of_hashes_emptied
    template = Reading::Config.new.hash[:item][:template]
    compacted = template.merge({ variants: [], experiences: [], notes: [] })

    assert_equal compacted, template.compact_by(template:)
  end

  # Cases where a hash IS NOT compacted:

  def test_equal_array_of_hashes_is_not_compacted_when_multiple_elements
    template =  { a: 1, b: [{ b1a: "one", b1b: "bar" },
                            { b2a: "two", b2b: "baz" }] }
    hash =      { a: 2, b: template[:b].dup }

    assert_equal hash, hash.compact_by(template:)
  end

  def test_equal_array_without_hashes_is_not_compacted
    template = { a: 1, b: ["one"] }
    hash =     { a: 2, b: ["one"] }

    assert_equal hash, hash.compact_by(template:)
  end

  def test_unequal_array_is_not_compacted
    template = { a: 1, b: ["one"] }
    hash =     { a: 2, b: ["two"] }

    assert_equal hash, hash.compact_by(template:)
  end

  def test_hash_without_array_is_not_compacted
    template = { a: 1, b: "string" }
    hash =     { a: 2, b: "another" }

    assert_equal hash, hash.compact_by(template:)
  end
end
