# Adds `describe` as an alias of `context` (from the shoulda-context gem).
module Minitest
  class Test
    class << self
      alias_method :describe, :context
    end
  end
end

# But wait, doesn't minitest/spec already provide `describe` blocks? Yes, but
# I get errors when using it alongside shoulda-context, so here I undefine it
# so that the alias above (`context` to `describe`) works correctly.
#
# Note: `describe` is monkey-patched into Kernel in minitest/spec, which is
# loaded into minitest/autorun, which I'm using.
Kernel.module_exec do
  undef describe if defined?(describe)
end
