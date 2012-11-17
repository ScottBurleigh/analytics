class DailyVisitsLoader
  def initialize db_connection, json_file
    @json_file = json_file
    @db = db_connection
  end
  def run
    @db.execute "drop table if exists dailyVisits"
    create_daily_visits_table
    insert_daily_visits
    enrich_isWeekday
    enrich_year_and_month
    enrich_views
  end
  def clear_daily_visits_table
    @db.execute "DELETE FROM dailyVisits"
  end
  def create_daily_visits_table
    columns = []
    columns << 
      "id integer primary key autoincrement" <<
      "date text" <<
      "visits int" <<
      "views int" <<
      "year int" <<
      "month int" <<
      "isWeekday text" 
    @db.execute "CREATE TABLE IF NOT EXISTS dailyVisits(" + 
      columns.join(",") + ")"
    @db.execute "CREATE UNIQUE INDEX IF NOT EXISTS dailyVisits_ix ON dailyVisits " +
      "(date)"
    @db.execute "CREATE INDEX IF NOT EXISTS dailyVisits_ym_ix ON dailyVisits " +
      "(year, month)"
  end
  def insert_daily_visits
    stmt = @db.prepare("insert into dailyVisits (date, visits) values (:date, :visits)")
    log "loading daily visits from json"
    input = JSON.parse(File.read(@json_file))
    input['rows'].each do |row|
      date = "%s-%s-%s" % [row[0][0..3], row[0][4..5], row[0][6..7]]
      stmt.execute(:date => date, :visits => row[1])
    end
  end
  def enrich_isWeekday
    weekend_stmt = @db.prepare "UPDATE dailyVisits SET isWeekday = 'F' WHERE " +
      day_clause(0,6) + " AND isWeekday is NULL"
    weekend_stmt.execute   
    weekday_stmt = @db.prepare "UPDATE dailyVisits SET isWeekday = 'T' WHERE " +
      day_clause(1,2,3,4,5) + " AND isWeekday is NULL"
    weekday_stmt.execute
  end
  def day_clause *nums
    "(" + nums.map {|n| "(strftime('%w', date) = '#{n}')"}.join(" OR ") + ")"
  end
  def enrich_year_and_month
    @db.execute "UPDATE dailyVisits " + 
      "SET month = strftime('%m', date) " +
      "WHERE month is NULL"
    @db.execute "UPDATE dailyVisits " + 
      "SET year  = strftime('%Y', date) " + 
      "WHERE year is NULL"
    # should be done in a single update statement but couldn't get it work
  end
  def enrich_views
    @db.execute "create temp view tmp as " +
      "select sum(views) as views, date from pageviews " + 
      "group by date"
    rs = @db.execute "select * from tmp"
    rs.each do |row|
      @db.execute("update dailyVisits set views = :views where date = :date",
                  :views => row['views'], :date => row['date'])
    end
    @db.execute "drop view tmp"      
   end
end
