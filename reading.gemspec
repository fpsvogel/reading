require_relative "lib/reading/version"

Gem::Specification.new do |spec|
  spec.name          = "reading"
  spec.version       = Reading::VERSION
  spec.authors       = ["Felipe Vogel"]
  spec.email         = ["fps.vogel@gmail.com"]

  spec.summary       = "reading parses a CSV reading log."
  spec.homepage      = "https://github.com/fpsvogel/reading"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.add_runtime_dependency "pastel", "~> 0.8"

  spec.add_development_dependency "debug", ">= 1.0.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters", "~> 1.0"
  spec.add_development_dependency "pretty-diffs"
  spec.add_development_dependency "amazing_print"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/fpsvogel/reading"
  spec.metadata["changelog_uri"] = "https://github.com/fpsvogel/reading/blob/master/CHANGELOG.md"

  # # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  # spec.files = Dir.chdir(File.expand_path(__dir__)) do
  #   `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  # end

  spec.files = Dir['lib/**/*.rb']

  spec.require_paths = ["lib"]
end
