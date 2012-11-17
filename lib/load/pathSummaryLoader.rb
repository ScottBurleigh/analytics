class PathSummaryLoader
  def initialize db_gateway, start_date, end_date
    @db = db_gateway
    @start_date = start_date
    @end_date = end_date
  end
  def run
    drop_path_summaries_table
    create_path_summaries_table
    create_blank_rows
    enrich_with_median_history
  end
  
  def create_path_summaries_table
    columns = []
    columns <<
      "id integer PRIMARY KEY AUTOINCREMENT" <<
      "path text" <<
      "medianHistory text"
    @db.execute "CREATE TABLE IF NOT EXISTS pathSummaries(" + 
      columns.join(",") + ")"
    @db.execute "CREATE INDEX IF NOT EXISTS path_summary_ix ON pathSummaries " +
      "(path)"
  end

  def drop_path_summaries_table
    @db.execute "drop table if exists pathSummaries"
  end

  def create_blank_rows
    @db.execute "insert into pathSummaries (path) select distinct path from monthviews"
  end
    
 
  def enrich_with_median_history
    MedianSparklineMaker.new(@db, @start_date, @end_date).run
  end
    
end
