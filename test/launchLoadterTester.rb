require "test/unit"

require 'test/extensions'
require 'test/testDB'

class LaunchLoaderTester < Test::Unit::TestCase
  def setup
    @conn = TestDB.conn
    @full = TestDB.full_conn
  end
  def test_seven_day_total
    actual = @full.get_first_value(
               "select total_7_days from launches " +
               "where path =  '/articles/lmax.html'")
    assert_equal 17716, actual
  end
  def test_history_json
    actual_string = @full.get_first_value(
                      "select history_json from launches " +
                      "where path =  '/articles/lmax.html'")
    actual = JSON.parse(actual_string)
    assert_equal 5603, actual[0]['views']
    assert_equal '2011-07-12', actual[0]['date']
    assert_equal 4, actual[3]['count']
  end
  def test_recent_median
    actual = @full.get_first_value(
                "select recent_median from launches " +
                "where path =  '/articles/lmax.html'")
    assert_equal 285, actual
  end
end
