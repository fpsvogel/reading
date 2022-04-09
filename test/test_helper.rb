$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rubygems"
require "bundler/setup"

require "debug"

require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use! [Minitest::Reporters::ProgressReporter.new(detailed_skip: false)]

require "reading/errors"

# def with_captured_stdout(print_also: false)
#   original_stdout = $stdout
#   yield if print_also
#   $stdout = StringIO.new
#   yield
#   $stdout.string
# ensure
#   $stdout = original_stdout
# end
