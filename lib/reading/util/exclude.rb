# Copied from activesupport/lib/active_support/core_ext/enumerable.rb
module Enumerable
  def exclude?(object)
    !include?(object)
  end
end

class String
  def exclude?(object)
    !include?(object)
  end
end
