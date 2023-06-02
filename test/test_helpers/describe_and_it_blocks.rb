require 'shoulda-context'

module DescribeAndItBlocks
  def self.extended(target)
    # The shoulda-context gem provides `context` and `should` blocks. I like
    # RSpec-style `describe` in addition to `context`, and `it` instead of `should`.
    class << target
      alias_method :describe, :context
      alias_method :it, :should
    end

    # But wait, doesn't minitest/spec already provide `describe` blocks? Yes, but
    # I get errors when using it alongside shoulda-context, so here I undefine it
    # so that the alias above (`context` to `describe`) works correctly.
    #
    # (Sidenote: Why is `describe` already defined, but not `it`? It's because
    # `describe` is monkey-patched into Kernel in minitest/spec, which is loaded
    # into minitest/autorun, which I'm using. `it` is also defined in minitest/spec,
    # but within Minitest::Spec which makes it apply only within a Minitest::Spec
    # (which `describe` sets up). See
    # https://github.com/minitest/minitest/blob/master/lib/minitest/spec.rb
    Kernel.module_exec do
      undef describe if defined?(describe)
    end
  end
end
