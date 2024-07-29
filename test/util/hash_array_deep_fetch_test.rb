require_relative "../test_helpers/test_helper"

class HashArrayDeepFetchTest < Minitest::Test
  using Reading::Util::HashArrayDeepFetch

  def test_array_deep_fetch
    array = ["a", ["ba", "bb"], "c"]

    assert_equal "bb", array.deep_fetch(1, 1)
  end

  def test_array_deep_fetch_index_error
    array = ["a", ["ba", "bb"], "c"]

    assert_raises(IndexError) do
      array.deep_fetch(1, 2)
    end
  end

  def test_hash_deep_fetch
    hash = { a: 1, b: { ba: 2, bb: 3 }, c: 4 }

    assert_equal 3, hash.deep_fetch(:b, :bb)
  end

  def test_hash_deep_fetch_key_error
    hash = { a: 1, b: { ba: 2, bb: 3 }, c: 4 }

    assert_raises(KeyError) do
      hash.deep_fetch(:b, :bc)
    end
  end

  def test_very_deep_fetch
    hash = { one: { two: { three: { four: { five: "ok" } } } } }

    assert_equal "ok", hash.deep_fetch(:one, :two, :three, :four, :five)
  end
end
