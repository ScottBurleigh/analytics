class LaunchLoader
  def initialize db, launch_list_file
    @launch_list_file = launch_list_file
    @db = db
    @db.results_as_hash = true
    @launches_list = nil
  end
  def run
    log 'loading launches'
    @db.execute "drop table if exists launches"
    create_launch_table
   # delete_data
    insert_rows launches_list
    enrich
  end

  def launches_list
    return @launches_list if @launches_list
    return [] unless File.exist? @launch_list_file
    lines = File.readlines(@launch_list_file)
    @launches_list = lines.map{|l| Launch.new(l.split[0], l.split[1])}
  end
  def paths
    launches_list.map(&:path)
  end
  def create_launch_table
    columns = []
    columns <<
      "id integer primary key autoincrement" <<
      "path string" <<
      "date string" <<
      "total_7_days integer" <<
      "total_28_days integer" <<
      "peak_day integer" <<
      "recent_median integer" <<
      "history string" <<
      "history_json string"

    @db.execute "CREATE TABLE IF NOT EXISTS launches (" + 
      columns.join(",") + ")"
    @db.execute "CREATE INDEX IF NOT EXISTS launches_ix ON launches " +
      "(path)"
  end
  def delete_data
    @db.execute "delete from launches"
    @db.execute "drop view if exists launch_seven_days"
  end
  def enrich
    enrich_total_days 7
    enrich_total_days 28
    enrich_workday_history 40
    enrich_peak_day
    generate_launch_json
    enrich_recent_median
  end
  def insert_rows launches
    launches.each do |l|
      @db.execute("insert into launches (path, date) values (:path, :date)",
                  :path =>l.path, :date => l.date_str)
    end
  end
  def enrich_total_days count
    create_post_launch_view 'tmp', count - 1
    paths.each do |path|
      totals = @db.get_first_row("select path, views, days from tmp " +
        "where path = ?", path)
      if totals && count == totals['days']
        @db.execute("update launches set total_#{count}_days = ? " +
                    "where path = ?", [totals['views'], path])
      end
    end
    @db.execute("drop view tmp")
  end
  def create_post_launch_view name, days
    stmt = "create temp view #{name} as " +
      "select path, sum(views) as views, count(views) as days " +
      "from launches as l join pageviews as v using (path) " + 
      "where v.date between l.date and date(l.date,'+#{days} day') " +
      "group by path "
    @db.execute stmt
  end


  def generate_launch_json 
    count = 40
    out_file = 'public/launch.json'
    result = {}
    launches_list.each do |launch|
      result[launch.path] = { 
        :data => launch_data(count, launch),
        :path => launch.path
      }
    end
    File.open(out_file, 'w') {|f| f << result.to_json}
  end

  def launch_data count, launch
    stmt = "select views, date from pageviews where " +
      "path = :path and " +
      "date >= :date and " +
      "isWeekDay = 'T' " +
      "order by date " +
      "limit :count"
    rs = @db.execute(stmt, :path => launch.path, 
                     :count => count, :date => launch.date_str)
    result = []
    rs.each_with_index do |r, ix|
        result << {:views => r['views'], :date => r['date'],
                   :count => ix + 1}
    end
    return result
  end

  def enrich_workday_history count
    #TODO remove history json from here
    stmt = "select views, date from pageviews where " +
      "path = :path and " +
      "date >= :date and " +
      "isWeekDay = 'T' " +
      "order by date " +
      "limit :count"
    launches_list.each do |launch|
      rs = @db.execute(stmt, :path => launch.path, 
                       :count => count, :date => launch.date_str)
      value = rs.map{|r| Math.log(r['views'])}.join(",")
      full_value = []
      rs.each_with_index do |r, ix|
        full_value << {:views => r['views'], :date => r['date'],
                      :count => ix + 1}
      end
      @db.execute("update launches set " +
                  "history = :value, history_json = :json where path = :path",
                  :path => launch.path, :value => value, 
                  :json => full_value.to_json)
    end
  end

  def enrich_recent_median
    launches_list.each do |launch|
      value = @db.get_first_value("select recent_median from recents where path = ?", launch.path)
      @db.execute("update launches set " +
                  "recent_median = :value where path = :path",
                  :path => launch.path, :value => value)
    end
  end

  def enrich_peak_day
    create_max_daily_view 'tmp', 40
    paths.each do |path|
      peak = @db.get_first_value("select max_views from tmp where path = ?", path)
      @db.execute("update launches set peak_day = ? where path = ?", [peak, path])
    end
  end

  def create_max_daily_view name, days
   stmt =  "create temp view #{name} as " +
      "select path, max(views) as max_views " +
      "from launches as l join pageviews as v using (path) " + 
      "where v.date between l.date and date(l.date,'+#{days} day') " +
      "group by path "
    @db.execute stmt
  end

end

class Launch
  attr_reader :path, :date
  def initialize path, date_str
    @path = path
    @date = Date.parse(date_str)
    check_validity
  end

  def date_str
    @date.strftime("%Y-%m-%d")
  end

  def check_validity
    log.error "missing leading / on %s" % @path unless @path.start_with?('/')
  end
end
