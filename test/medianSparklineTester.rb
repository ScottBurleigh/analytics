require "test/unit"
require 'test/testDB'
require 'test/extensions'


class MedianSparklineTester < Test::Unit::TestCase
  def setup
    @conn = TestDB.conn
  end

  def example_data
    # from "select median from monthviews where path = '/' order by year, month"
    [790, 790, 814, 841, 801, 835, 708, 770, 692, 755, 792, 
     819, 738, 805, 824, 789, 743, 816, 676, 778, 824, 815, 740, 828, 805]
  end
  def example_nil_data
    # sparklines does not like nil, will need to process 
    [790, 790, 814, 841, nil, 835, 708, 770, 692, 755, 792, 
     819, 738, 805, 824, 789, 743, 816, 676, 778, 824, 815, 740, 828, 805]
  end
  def xtest_nowt
    prod = SQLite3::Database.open DB_FILE  
    rs = prod.execute "select median from monthviews where path = '/' order by year, month"
    Sparklines.plot_to_file('foo.png', example_nil_data, :type => 'bar', :height => 30, :upper => 1000)
  end
  def test_extracts_sparkline_data_from_db
    db = DataGateway.new
    db.connection = TestDB.full_conn
    loader = MedianSparklineMaker.new(db, nil, nil)
    table = loader.get_median_history('/')
    assert_equal [816, 676, 778, 824], table.map{|r| r['median']}
  end
  def test_fill_gap_for_sparklines_does_not_alter_if_full
    loader = MedianSparklineMaker.new(nil, Date.new(2011,11,1), Date.new(2012,2,2))
    actual = loader.fill_median_history(example_table)
    assert_equal [816, 676, 778, 824], actual.map{|r| r['median']}    
  end
  def test_fill_gap_for_sparklines_adds_zeros_at_start
    loader = MedianSparklineMaker.new(nil, Date.new(2011,8,1), Date.new(2012,2,2))
    actual = loader.fill_median_history(example_table)
    assert_equal [0, 0, 0, 816, 676, 778, 824], actual.map{|r| r['median']}    
  end
  def test_fill_gap_for_sparkline_fills_missing_in_middle
    loader = MedianSparklineMaker.new(nil, Date.new(2011,10,1), Date.new(2012,2,2))
    data = example_table.reject{|r| 1 == r['month'] }
    actual = loader.fill_median_history(data)
    assert_equal [0, 816, 676, 676, 824], actual.map{|r| r['median']}    
  end
  def example_table
    [{5=>1, 0=>1, "median"=>816, 6=>13632, "month"=>11, 1=>"/", "total"=>13632, 2=>2011, "rank"=>1, "id"=>1, 3=>11, "year"=>2011, "path"=>"/", 4=>816}, {5=>1, 0=>4, "median"=>676, 6=>17801, "month"=>12, 1=>"/", "total"=>17801, 2=>2011, "rank"=>1, "id"=>4, 3=>12, "year"=>2011, "path"=>"/", 4=>676}, {5=>1, 0=>7, "median"=>778, 6=>22718, "month"=>1, 1=>"/", "total"=>22718, 2=>2012, "rank"=>1, "id"=>7, 3=>1, "year"=>2012, "path"=>"/", 4=>778}, {5=>1, 0=>10, "median"=>824, 6=>20981, "month"=>2, 1=>"/", "total"=>20981, 2=>2012, "rank"=>1, "id"=>10, 3=>2, "year"=>2012, "path"=>"/", 4=>824}]
  end
  def test_enriches_path_summary_data
    start = Date.new(2011,11, 05)
    finish = Date.new(2012,02,02)
    db = DataGateway.new
    db.connection = @conn
    @conn.transaction
    begin
      quiet do
        PageviewLoader.new(@conn, nil, nil).enrich
        MonthLoader.new(@conn, start, finish).run
        builder = PathSummaryLoader.new(db, start, finish)
        builder.run
      end
      actual = @conn.get_first_value("SELECT medianHistory from pathSummaries WHERE path = '/'")
      expected = "816,676,778,824"
      assert_equal expected, actual
    ensure
      @conn.rollback
    end
  end
end
