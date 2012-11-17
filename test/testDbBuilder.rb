class TestDbBuilder
  def initialize sourceDB, testDB
    @sourceDB_file = sourceDB
    @testDB_file = testDB
    @start_date = '2011-11-10'
    @end_date = '2012-04-20'
    @paths = %w[/ /bliki/index.html /books.html]
  end
  def run
    make_connections
    create_tables
    transfer_data
  end

  def create_tables
    loader = PageviewLoader.new(@testDB, nil, nil)
    loader.create_pageviews_table
  end
  
  def make_connections
    @sourceDB = SQLite3::Database.open @sourceDB_file
    @sourceDB.results_as_hash = true
    @testDB = SQLite3::Database.open @testDB_file
  end
  
  def insert_test json
     @insert_stmt =  @testDB.prepare "insert into pageviews (path, date, views) values (:path, :date, :views)" 
    @insert_stmt.execute(JSON.parse(json))
  end

  def transfer_data
    transfer_3_month_data
    transfer_launch_data
    insert_launch_rows
  end

  def transfer_3_month_data 
    stmt = @sourceDB.prepare("select path, date, views from pageviews WHERE " +
      "date > :start AND date < :end AND path = :path")
    @paths.each do |p| 
      rs = stmt.execute(:start => @start_date, :end => @end_date, :path => p)
      rs.each {|r| insert_test r.to_json}
    end
  end
  def transfer_launch_data
    stmt = @sourceDB.prepare("select path, date, views from pageviews WHERE " +
                                        "path = '/articles/lmax.html'")
    rs = stmt.execute
    rs.each {|r| insert_test r.to_json}
  end
  def insert_launch_rows
    loader = LaunchLoader.new(@testDB)
    loader.create_launch_table
    loader.insert_rows [Launch.new('/articles/lmax.html', '2011-07-12')]
  end
end
