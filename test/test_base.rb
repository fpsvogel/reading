$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

class TestBase < Minitest::Test
  self.class.attr_reader :files, :items, :config, :error_log

  def setup
    self.class.clear_error_log
  end

  def items
    self.class.items
  end

  def files
    self.class.files
  end

  def config
    self.class.config
  end

  def error_log
    self.class.error_log
  end

  def self.clear_error_log
    @error_log = []
  end
end
