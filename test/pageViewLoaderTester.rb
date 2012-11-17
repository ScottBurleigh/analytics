require "test/unit"
require 'test/extensions'
require 'test/testDB'

class PageViewLoaderTester < Test::Unit::TestCase
  def setup
    @conn = TestDB.conn
    @loader = PageviewLoader.new(@conn, nil, nil)
  end
  def test_enrich_db_with_weekday_flag
    @conn.transaction 
    begin
      quiet{@loader.enrich_days_of_week}
      assert_equal('F', get_isWeekday('2012-01-07'))
      assert_equal('T', get_isWeekday('2012-01-06'))
    ensure
      @conn.rollback
    end
  end
  def get_isWeekday dateStr
    stmt = @conn.prepare("select isWeekday from pageviews where date = ?")
    rs = stmt.execute(dateStr)
    result = rs.first['isWeekday']
    rs.close
    return result
  end
  def test_enrich_with_year_and_month
    @conn.transaction 
    begin
      quiet{@loader.enrich_year_and_month}
      row = @loader.get_pageview('/', '2012-01-07')[0]
      assert_equal(1, row['month'])
      assert_equal(2012, row['year'])
    ensure
      @conn.rollback
    end
  end
end
