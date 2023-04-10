$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rubygems"
require "bundler/setup"

require "debug"

require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new(detailed_skip: false)]

require "shoulda-context"
require "pretty_diffs"

module Minitest
  class Test
    include PrettyDiffs
  end
end

require "date"

# Stub Date::today so that the endless date ranges in parse_test.rb aren't needlessly long.
class Date
  class << self
    alias_method :original_today, :today

    def today
      Date.new(2022,10,1)
    end
  end
end
