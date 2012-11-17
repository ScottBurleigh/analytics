require 'sqlite3'
require 'forwardable'
class DataGateway
  extend Forwardable
  def initialize db_file = nil
    @db = nil
    if db_file
      self.connection = SQLite3::Database.open db_file
    end
  end
  def connection= conn
    raise "don't change connection" if @db
    @db = conn
    @db.results_as_hash = true
    add_custom_functions
  end

  def_delegators :@db, :execute, :results_as_hash=, :get_first_row, :get_first_value, :prepare
  
  def get_monthview path, year, month
    @db.get_first_row("select * from monthviews where path = ? and year = ? and month = ?", [path, year, month])
  end
  def get_monthviews_for_path path
    @db.execute("select * from monthviews where path = ? " + 
                      "order by year, month", path)
  end
  def add_custom_functions
    @db.create_aggregate_handler( MedianAggregateHandler )
     # info for this at http://sqlite-ruby.rubyforge.org/sqlite3/classes/SQLite3/Database.html#M000115
  end

  class MedianAggregateHandler
    def self.arity
      1
    end

    def self.name
      "median"
    end

    def initialize 
      @values = []
    end

    def step func, value
      @values << value
    end

    def finalize func
      func.result = @values.sort[@values.size / 2]
      initialize #work around for initialization bug

      # mention using pry here to deal with incorrect docs
    end
  end
end
