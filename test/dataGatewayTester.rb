require "test/unit"

class DataGatewayTester < Test::Unit::TestCase
  def setup
    @conn = TestDB.full_conn
    @db = DataGateway.new
    @db.connection = @conn
  end
  def test_get_monthview_via_key
    row = @db.get_monthview('/', 2012, 1)
    assert_equal 778, row['median']
  end
  def test_create_median_function
    #@conn.create_aggregate_handler( DataGateway::MedianAggregateHandler )

    actual = @db.get_first_value("select median(views) from pageViews where path = '/'")
    assert_equal(722, actual)
  end
end
