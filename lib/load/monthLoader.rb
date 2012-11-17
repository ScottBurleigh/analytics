require 'month'

class MonthLoader
  def initialize db_conn, start_date, end_date
    @db = db_conn
    @start_date = start_date
    @end_date = end_date
  end

  def run
    log "running month loader"
    create_month_views_table
    create_indexes
    months.each {|m| ensure_month m}
    enrich_ranks
  end

  def months
    Month.from_date(@start_date)..Month.from_date(@end_date)
  end

  def create_month_views_table
    columns = []
    columns <<
      "id integer primary key autoincrement" <<
      "path text" <<
      "year integer" <<
      "month integer" <<
      "median integer" <<
      "rank integer" <<
      "total integer"
    @db.execute "create table if not exists monthViews(" + 
      columns.join(",") + ")"
  end
  def create_indexes
    @db.execute "CREATE INDEX IF NOT EXISTS path_ix ON monthviews " +
      "(path)"
    @db.execute "CREATE INDEX IF NOT EXISTS date_ix ON monthviews " +
      "(year, month)"
    @db.execute "CREATE INDEX IF NOT EXISTS key_ix ON monthviews " +
      "(path, year, month)"
  end

  def ensure_month aMonth
    paths = paths_for(aMonth)
    existing_month_views = select_month_views aMonth
    return if existing_month_views.size == paths.size
    log "loading monthly data for %s", aMonth
    delete_month_views aMonth unless existing_month_views.empty?    
    paths_for(aMonth).each {|p| load_month(aMonth, p)}
  end

  def delete_month_views aMonth
    @db.execute("DELETE FROM monthviews WHERE (month = ?) AND (year = ?)",
                [aMonth.month, aMonth.year])
  end
  def select_month_views aMonth
    stmt = @db.prepare "SELECT * FROM monthviews WHERE " +
      "(month = ?) AND (year = ?)"
    rs = stmt.execute(aMonth.month, aMonth.year)
    result = rs.map{|r| {:path => r['path'], 
        :month => r['month'], :year => r['year']}}
    return result      
  end

  def paths_for aMonth
    stmt_text = "select distinct path from pageviews where " +  date_clause(aMonth)
    paths = @db.execute(stmt_text)
    return paths.map{|r| r['path']}
  end

  def load_month aMonth, pathStr
    median = median_weekday_views(aMonth, pathStr)
    total = total_views(aMonth, pathStr)
    insert pathStr, aMonth, median, total
  end

  def insert pathStr, aMonth, median, total
    @insert_stmt ||= @db.prepare "insert into monthViews " +
      "(path, year, month, median, total) " +
      "values (?, ?, ?, ?, ?)"
    @insert_stmt.execute(pathStr, aMonth.year, aMonth.month, median, total)
  end

  def median_weekday_views aMonth, pathStr
    row = @db.get_first_row "select count(views), median(views) from pageviews where " + 
      date_clause(aMonth) + 
      " AND path = :path " + " AND isWeekday = 'T'", :path => pathStr
    return (row[0] > 10) ? row[1] : 0
  end

  def total_views aMonth, pathStr
    @db.get_first_value("SELECT sum(views) as result FROM pageviews WHERE " +
      "path = ? AND " + date_clause(aMonth), 
       pathStr)
  end
  

  def date_clause aMonth
    " month = '%s' AND year = '%s' " % 
      [aMonth.month, aMonth.year]
    # see note on prepared statement below
  end
  
  def enrich_ranks
    log 'enriching ranks'
    months.each {|m| enrich_ranks_for m}
  end

  def enrich_ranks_for aMonth
    stmt = "select * from monthviews WHERE " + date_clause(aMonth) + 
      "ORDER BY median DESC LIMIT 200"
    rs = @db.execute(stmt)
    rs.each_with_index do |row, ix|
      @db.execute("update monthviews set rank = ? where path = ? AND " +
                  date_clause(aMonth), 
                  [ix + 1, row['path']])
    end
  end

end


# it would be better to use a prepared statement rather than the
# date_clause string concatentation. However I couldn't get the
# prepared statement to work for that case in my first formulaation of
# that query. It was not helpful that the database cannot show how
# prepared statements are filled in for execution. Now have enriched
# pageviews table with year and month it may work better
