require 'rubygems'
require 'bundler/setup'

require 'debug'

require 'minitest/autorun'
require 'minitest/reporters'
Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new(detailed_skip: false)]


require 'pretty_diffs'

module Minitest
  class Test
    include PrettyDiffs
  end
end


Gem.find_files('reading/util/*.rb').each { |f| require f }


require 'date'

# Stub Date::today so that the endless date ranges in parse_test.rb aren't needlessly long.
class Date
  class << self
    alias_method :original_today, :today

    def today
      Date.new(2022,10,1)
    end
  end
end
