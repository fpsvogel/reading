# frozen_string_literal: true

require_relative "lib/reading/csv/load/version"

Gem::Specification.new do |spec|
  spec.name          = "reading-csv-load"
  spec.version       = Reading::CSV::Load::VERSION
  spec.authors       = ["Felipe Vogel"]
  spec.email         = ["fps.vogel@gmail.com"]

  spec.summary       = "reading-csv-load parses a CSV reading list."
  spec.homepage      = "https://github.com/fpsvogel/reading-csv-load"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/fpsvogel/reading-csv-load"
  spec.metadata["changelog_uri"] = "https://github.com/fpsvogel/reading-csv-load/blob/master/CHANGELOG.md"

  # spec.files = ["lib/reading/csv/load.rb",
  #               "lib/reading/csv/errors.rb",
  #               "lib/reading/csv/util.rb"
  #               "README.md", "LICENSE.txt"]

  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]
end
