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

  spec.add_runtime_dependency "pastel"

  spec.add_development_dependency "debug"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "pretty-diffs"
  spec.add_development_dependency "amazing_print"
  spec.add_development_dependency "rubycritic"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/fpsvogel/reading"
  spec.metadata["changelog_uri"] = "https://github.com/fpsvogel/reading/blob/master/CHANGELOG.md"

  # # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  # spec.files = Dir.chdir(File.expand_path(__dir__)) do
  #   `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  # end

  spec.files = Dir['lib/**/*.rb']

  spec.bindir = 'bin'
  spec.executables << 'reading'

  spec.require_paths = ["lib"]
end
