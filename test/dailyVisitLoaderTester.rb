require "test/unit"
require 'test/extensions'
require 'test/testDB'

class DailyVisitLoaderTester < Test::Unit::TestCase
  def setup
    @conn = TestDB.conn
    @full = TestDB.full_conn
  end
  def loader
    DailyVisitsLoader.new(@conn, 'test/data_src/visits')
  end
  def test_load_from_json
    actual =  @full.get_first_value("select visits from dailyVisits where date = '2012-01-10'")
    assert_equal 14539, actual
  end
  def test_enrich_with_isWeekday
    assert_equal('F', get_isWeekday('2012-01-07'))
    assert_equal('T', get_isWeekday('2012-01-06'))
  end
  def get_isWeekday dateStr
    @full.get_first_value("select isWeekday from dailyVisits where date = ?", 
                          dateStr)
  end
  def test_enrich_with_year_and_month
    actual_month = @full.get_first_value "select month from dailyVisits where date = '2012-01-10'"
    assert_equal 1, actual_month
    actual_year =  @full.get_first_value "select year from dailyVisits where date = '2012-01-10'"
    assert_equal 2012, actual_year
  end
  def test_avoid_duplicate_inserts
    @conn.transaction
    begin
      loader.run
      loader.run
      count = @conn.get_first_value("select count(*) from dailyVisits where date = '2012-01-10'")
      assert_equal 1, count                                    
    ensure
      @conn.rollback
    end
  end
  def test_enrich_views
    actual =  @full.get_first_value("select views from dailyVisits where date = '2012-01-10'")
    assert_equal 2366, actual
  end

end
