require "test/unit"
require 'test/extensions'
require 'test/testDB'

class MonthVisitsLoaderTester < Test::Unit::TestCase

  def setup
    @conn = TestDB.conn
    @full = TestDB.full_conn
  end

  def month_visits_loader
    start = Date.new(2011,11, 05)
    end_date = Date.new(2012,02,02)
    return MonthVisitsLoader.new(@conn, start, end_date)
  end

  def load_daily_visits
    DailyVisitsLoader.new(@conn, 'test/data_src/visits').run
  end

  def test_loads_visit_totals
    actual = @full.get_first_value "select totalVisits from monthVisits where year = '2012' and month = '1'"
    assert_equal 268378, actual
  end

  def test_loads_median_visits
    actual = @full.get_first_value "select medianVisits from monthVisits where year = '2012' and month = '1'"
    assert_equal 9439, actual
  end
  def test_handle_median_with_no_results
    start = Date.new(2011,11, 05)
    finish = Date.new(2012,05,02)
    loader = MonthVisitsLoader.new(@conn, start, finish, 'test/data_src/monthly_unique_visitors')
    @conn.transaction
    begin
      load_daily_visits
      loader.run
    ensure
      @conn.rollback
    end
  end
  def test_loads_total_views
    actual = @full.get_first_value "select totalViews from monthVisits where year = '2012' and month = '1'"
    assert_equal 52468, actual
  end  
  def test_loads_median_views
    actual = @full.get_first_value("select medianViews from monthVisits " +
                                   "where year = '2012' and month = '1'")
    assert_equal 1809, actual
  end
end
