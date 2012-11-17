require "test/unit"

class MonthTester < Test::Unit::TestCase
  def test_make_range_from_months
    start = Date.new(2011,11, 05)
    finish = Date.new(2012,02,02)
    range = Month.from_date(start)..Month.from_date(finish)
    assert_equal 4, range.count
  end
  def test_checks_for_null_arg
    begin
      m = Month.from_date(nil)
      flunk
    rescue ArgumentError
      # expected behaior
    end
  end
 end
