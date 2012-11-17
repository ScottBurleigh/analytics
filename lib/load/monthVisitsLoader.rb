require 'month'

class MonthVisitsLoader
  def initialize db_conn, start_date, end_date, monthly_visitors_file
    raise "no db connection" unless db_conn
    @db = db_conn
    @start_date = start_date
    @end_date = end_date
    @monthly_visitors_file = monthly_visitors_file
  end

  def run
    log "enriching with month visits"
    create_month_visits_table
    delete_data
    insert_month_total_visits
    months.each {|m| enrich_median_weekday_visits m}
    monthly_visitors_data = JSON.parse(File.read(@monthly_visitors_file))
    months.each {|m| load_monthly_visitors m, monthly_visitors_data}
    enrich_total_views   
    enrich_median_views
  end

  def months
    Month.range(@start_date, @end_date)
  end

  def create_month_visits_table
    columns = []
    columns <<
      "id integer primary key autoincrement" <<
      "year integer" <<
      "month integer" <<
      "medianVisits integer" <<
      "totalVisits integer" <<
      "totalViews integer" <<
      "uniqueVisitors integer" <<
      "medianViews integer"

    @db.execute "CREATE TABLE IF NOT EXISTS monthVisits (" + 
      columns.join(",") + ")"
    @db.execute "CREATE INDEX IF NOT EXISTS month_visits_ix ON monthVisits " +
      "(year, month)"
  end

  def delete_data
    @db.execute "delete from monthVisits"
  end

  def insert_month_total_visits
    @db.execute "insert into monthVisits (totalVisits, year, month) " + 
      "select sum(visits), year, month from dailyVisits " +
      "group by year, month"
  end

  def enrich_median_weekday_visits aMonth
    visits = median_weekday_visits(aMonth)
    return unless visits
    @db.execute("UPDATE monthVisits SET medianVisits = :visits " +
                "WHERE year = :year AND month = :month ",
                :year => aMonth.year, :month => aMonth.month, 
                :visits => visits)
  end
                
  def median_weekday_visits aMonth
    rs = @db.execute "SELECT visits FROM dailyVisits " +
      "WHERE year = :year AND month = :month AND isWeekday = 'T' " +
      "ORDER BY visits", [:year => aMonth.year, :month => aMonth.month]
   if rs.empty?
      return nil 
   else
     return rs[rs.size/2]['visits']
   end
  end

  def load_monthly_visitors aMonth, data
    row = data['rows'].detect{|r| r[0] == aMonth.monthStr and r[1] == aMonth.year.to_s}
    @db.execute("UPDATE monthVisits SET uniqueVisitors = :visitors " +
                "WHERE year = :year AND month = :month ",
                :year => aMonth.year, :month => aMonth.month, 
                :visitors => row[2].to_i)
  end


  def enrich_total_views
    with_view_total_views do
      rs = @db.execute "select * from tmp"
      rs.each do |row|
        @db.execute("update monthVisits set totalViews = :views " + 
                    "where month = :month and year = :year",
                    :month => row['month'], :year => row['year'],
                    :views => row['t'])
      end
    end
  end

  def with_view_total_views
    @db.execute "create temp view tmp as " + 
      "select year, month, sum(views) as t " + 
      "from pageviews join monthVisits using (year, month) " + 
      "group by month, year"
    yield
    @db.execute "drop view tmp"
  end
  
  def enrich_median_views
    @db.execute "create temp view tmp as " +
      "select median(views) as m, month, year " +
      "from dailyVisits group by month, year"
    rs = @db.execute "select * from tmp"
    rs.each do |row|
      @db.execute("update monthVisits set medianViews = :views " +
                    "where month = :month and year = :year",
                    :month => row['month'], :year => row['year'],
                    :views => row['m'])
    end
    @db.execute "drop view tmp"

  end

end
