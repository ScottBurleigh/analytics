require 'month'

class PageviewLoader
  def initialize db_connection, date_range = nil, input_dir = nil
    @db = db_connection
    @db.results_as_hash = true
    @date_range = date_range
    @input_dir = input_dir
  end
  def create_pageviews_table
    columns = []
    columns << 
      "id integer primary key autoincrement" <<
      "path text" <<
      "date text" <<
      "views int" <<
      "year int" <<
      "month int" <<
      "dayOfWeek text" <<
      "isWeekday text" 
    @db.execute "create table if not exists pageviews(" + 
      columns.join(",") + ")"

  end
  def close
    @db.close
  end

  def run 
    create_pageviews_table
    insert_pageviews_table if @date_range
    enrich
  end

  def load_pageviews_from_files
    create_pageviews_table
    insert_pageviews_table
  end

  def insert_pageviews_table
    stmt = @db.prepare("insert into pageviews (path, date, views) values (:path, :date, :views)")
    @date_range.each do |day|
      date = day.to_s
      log 'loading %s', date
      @db.execute("delete from pageviews where date = ?", date)
      in_file = @input_dir + date
      raise 'heck' if has_page_views? date
      input = JSON.parse(File.read(in_file))
      input['rows'].each do |row|
        stmt.execute(:path => row[0], :date => date, :views => row[1])
      end
    end
  end
  def has_page_views? dateString
    0 != @db.get_first_value("select count(*) from pageviews where date = ?", 
                            dateString)
    
  end
  def enrich
    enrich_days_of_week
    enrich_year_and_month
    create_month_index
  end
  def enrich_days_of_week
    log 'enriching days of week'
    weekend_stmt = @db.prepare "UPDATE pageviews SET isWeekday = 'F' WHERE " +
      day_clause(0,6) + " AND isWeekday is NULL"
    weekend_stmt.execute   
    weekday_stmt = @db.prepare "UPDATE pageviews SET isWeekday = 'T' WHERE " +
      day_clause(1,2,3,4,5) + " AND isWeekday is NULL"
    weekday_stmt.execute
  end
  def enrich_year_and_month
    where_clause = "WHERE month is NULL"
    @db.execute "UPDATE pageviews " + 
      "SET month = strftime('%m', date) " +
      "WHERE month is NULL"
    @db.execute "UPDATE pageviews " + 
      "SET year  = strftime('%Y', date) " + 
      "WHERE year is NULL"
    # should be done in a single update statement but couldn't get it work
  end

  def create_month_index
    @db.execute "CREATE INDEX IF NOT EXISTS month_ix ON pageviews " +
      "(path, year, month)"
  end

  def day_clause *nums
    "(" + nums.map {|n| "(strftime('%w', date) = '#{n}')"}.join(" OR ") + ")"
  end

  def get_pageview path, date
    stmt = @db.prepare("SELECT * FROM pageviews WHERE " + 
                       "date = :date AND path = :path")
    rs = stmt.execute(:path => path, :date => date)
    result = rs.to_a
    rs.close
    return result
  end
 
end
