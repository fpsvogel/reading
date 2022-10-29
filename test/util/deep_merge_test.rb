require_relative "../test_helper"

require "reading/util/deep_merge"

class DeepMergeTest < Minitest::Test
  using Reading::Util::DeepMerge

  def test_deep_merge_pure_hashes_like_active_support
    hash_1 = { a: { aa: 1 } }
    hash_2 = { a: { ab: 2 } }
    deep_merged = { a: { aa: 1, ab: 2 } }

    assert_equal deep_merged, hash_1.deep_merge(hash_2)
  end

  def test_deep_merge_arrayed_hashes_of_equal_length
    hash_1 = { a: [{ a1a: 1, a1b: 2 },
                   { a2a: 10 }] }
    hash_2 = { a: [{ a1c: 3 },
                   { a2b: 11 }] }
    deep_merged = { a: [{ a1a: 1, a1b: 2, a1c: 3 },
                        { a2a: 10, a2b: 11 }] }

    assert_equal deep_merged, hash_1.deep_merge(hash_2)
  end

  def test_deep_merge_arrayed_hashes_first_longer
    hash_1 = { a: [{ a1a: 1, a1b: 2 },
                   { a2a: 10 },
                   { a3a: 20 }] }
    hash_2 = { a: [{ a1c: 3 },
                   { a2b: 11}] }
    deep_merged = { a: [{ a1a: 1, a1b: 2, a1c: 3 },
                        { a2a: 10, a2b: 11 },
                        { a3a: 20 }] }

    assert_equal deep_merged, hash_1.deep_merge(hash_2)
  end

  def test_deep_merge_arrayed_hashes_first_shorter
    hash_1 = { a: [{ a1a: 1, a1b: 2 },
                   { a2a: 10 }] }
    hash_2 = { a: [{ a1c: 3 },
                   { a2b: 11},
                   { a3a: 20 }] }
    deep_merged = { a: [{ a1a: 1, a1b: 2, a1c: 3 },
                        { a2a: 10, a2b: 11 },
                        { a3a: 20 }] }

    assert_equal deep_merged, hash_1.deep_merge(hash_2)
  end

  def test_deep_merge_arrayed_hashes_with_same_key
    hash_1 = { a: [{ a1a: 1 }], b: 3 }
    hash_2 = { a: [{ a1a: 2 }], b: 4 }
    deep_merged = { a: [{ a1a: 2 }], b: 4 }

    assert_equal deep_merged, hash_1.deep_merge(hash_2)
  end

  def test_deep_merge_arrayed_hashes_with_block
    hash_1 = { a: [{ a1a: 1 }], b: 3 }
    hash_2 = { a: [{ a1a: 2 }], b: 4 }
    deep_merged = { a: [{ a1a: 1 }], b: 3 }

    assert_equal deep_merged,
      hash_1.deep_merge(hash_2) { |key, v1, v2| [v1, v2].min }
  end
end
