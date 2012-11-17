require "test/unit"
require 'test/extensions'
require 'test/testDB'


class MonthLoaderTester < Test::Unit::TestCase
  def setup
    @conn = TestDB.conn
    @full = TestDB.full_conn
  end
  
  def jan_root_where_clause
    " WHERE month = '01' AND year = '2012' AND path = '/'"
  end
  def month_loader
      start = Date.new(2011,11, 05)
      end_date = Date.new(2012,02,02)
      return MonthLoader.new(@conn, start, end_date)
  end
  def enrich_pageviews
    quiet{PageviewLoader.new(@conn, nil, nil).enrich}
  end
  def test_paths_for_month
    loader = MonthLoader.new(@conn, nil, nil)                             
    paths = loader.paths_for(Month.new(2011,12))
    expected = %w[/ /books.html /bliki/index.html /articles/lmax.html].sort
    assert_equal expected, paths.sort
  end
  def test_determine_median_weekday_views
    @conn.transaction
    begin
      enrich_pageviews
      loader = MonthLoader.new(@conn, nil, nil)
      assert_equal 778, loader.median_weekday_views(Month.new(2012,1), '/')
    ensure
      @conn.rollback
    end
  end
  def test_if_not_enough_results_median_is_zero
    @conn.transaction
    begin
      victims = @conn.execute "select rowid from pageviews where " + 
        "path = '/' and month = '12'"
      victims[1..20].each do |v|
        @conn.execute "delete from pageviews where rowid = ? ", v[0]
      end
       # surviviors = @conn.execute "select views from pageviews where " + 
       #   "path = '/' and month = '12' order by views"
       # puts surviviors.inspect
      quiet do 
        enrich_pageviews
        month_loader.run
      end
      assert_equal 0, month_loader.median_weekday_views(Month.new(2011,12), '/')
    ensure
      @conn.rollback
    end
  end
  def test_creates_monthly_table
    actual = @full.get_first_row("select * from monthViews where path = '/' and year = '2012' and month = '01'")
    assert_equal 778, actual['median']
    assert_equal 22718, actual['total']
  end
  def test_determine_total_views
    loader = MonthLoader.new(@conn, nil, nil)
    enrich_pageviews
    expected = @conn.get_first_value("select sum(views) from pageviews where path = '/' and date >= '2012-01-01' and date < '2012-02-01'")
    actual = loader.total_views(Month.new(2012,1), '/')
    assert_equal expected, actual
  end
  def test_month_loader_does_not_create_dupicates
    @conn.transaction
    count_stmt = "select count(*) from monthViews where month = '01' and year = '2012'"
    begin
      quiet do 
        enrich_pageviews
        month_loader.run
        assert_equal 4, @full.get_first_value(count_stmt)
        month_loader.run
        assert_equal 4, @conn.get_first_value(count_stmt)
      end
    ensure
      @conn.rollback
    end
  end
  def test_month_with_some_values_will_build_all_values
   @conn.transaction
    count_stmt = "select count(*) from monthViews where month = '01' and year = '2012'"
    begin
      quiet do
        enrich_pageviews
        month_loader.run
        assert_equal 4, @conn.get_first_value(count_stmt)
        @conn.execute "delete from monthViews where month = '01' and year = '2012' and path = '/'"
        month_loader.run
        assert_equal 4, @conn.get_first_value(count_stmt)
      end
    ensure
      @conn.rollback
    end
  end
  def test_enriches_ranks
    actual = @full.get_first_value("select rank from monthviews" + jan_root_where_clause)
    assert_equal 1, actual
  end
end
