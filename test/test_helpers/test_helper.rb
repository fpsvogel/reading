require "rubygems"
require "bundler/setup"

require "debug"

require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new(detailed_skip: false)]

require "shoulda-context"
require_relative "describe_blocks"

require "pretty_diffs"

module Minitest
  class Test
    include PrettyDiffs
  end
end


# For some reason, this doesn't work outside the test environment if the gem is
# not installed. So elsewhere it's
# Dir[File.join(__dir__, "reading", "util", "*.rb")].each { |file| require file }
Gem.find_files("reading/util/*.rb").each { |f| require f }


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
