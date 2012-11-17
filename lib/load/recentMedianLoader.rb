class RecentMedianLoader
  def initialize db, finish_date = Date.today
    @db = db
    @finish_date = finish_date - 1
    @start_date = @finish_date - 7
  end
  
  def run
    log "loading recent medians"
    @db.execute "drop table if exists recents"   
    create_recents_table
    load_data
  end

  def create_recents_table
    columns = []
    columns <<
      "path text primary key" <<
      "recent_median integer" <<
      "count integer"
    @db.execute "create table if not exists recents(" + 
      columns.join(",") + ")"
    @db.execute "CREATE INDEX IF NOT EXISTS recents_path_ix ON recents " +
      "(path)"
  end


  def load_data
    start = sql_date(@start_date)
    finish = sql_date(@finish_date)
    stmt = ("create temp view v_recents as " + 
                "select median(views) as recent_median, " + 
                "count(views) as count, path from pageviews " +
                "where date <= date('#{finish}') and date > date('#{start}') " +
                " and isWeekDay = 'T' " +
                "group by path")
    @db.execute stmt
    rs = @db.execute "insert into recents select path, recent_median, count from v_recents "
  end

  def sql_date aDate
    aDate.strftime("%Y-%m-%d")
  end

    
end
