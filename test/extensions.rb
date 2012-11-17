class Test::Unit::TestCase
  def quiet &block
    log_with_level(Logger::WARN, &block)
  end
end
