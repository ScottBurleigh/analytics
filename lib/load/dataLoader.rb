require 'dataGateway'

require 'date'
require 'sqlite3'
require 'yaml'


class DataLoader
  def initialize data_dir, date_range = nil
    @data_dir = data_dir
    load_config
    @raw_data_dir = @data_dir + 'dailyViews/'
    @raw_visits_file = @data_dir + 'visits'
    @monthly_visitors_file = @data_dir + 'monthly_unique_visitors'
    @auth_token = File.read(@data_dir + 'auth-token')
    @launch_list = @data_dir + 'launch-list.txt'
    @db_file = @data_dir + 'data.db'
    @refresh_date_range = date_range ||= last_download_date..yesterday
    @db = nil
    @finish_day = @refresh_date_range.end
  end

  def load_config
    config = YAML::load(File.read(@data_dir + 'config.yaml'))
    @profile_id = config['profile_id']  || raise("no profileid")
    @start_day = config['start_day']        || raise("no start day")
  end

  def rebuild
    @refresh_date_range = @start_day..yesterday
    load_pageviews_from_files
    enrich_db
  end

  def run
    download_from_google
    load_pageviews_from_files
    enrich_db
  end

  def load_pageviews_from_files
    ensure_db_conn
    PageviewLoader.new(@db, @refresh_date_range, @raw_data_dir).load_pageviews_from_files
  end

  

  def enrich_db
    ensure_db_conn
    PageviewLoader.new(@db).enrich
    DailyVisitsLoader.new(@db, @raw_visits_file).run
    RecentMedianLoader.new(@db, @finish_day).run
    MonthVisitsLoader.new(@db, @start_day, @finish_day, @monthly_visitors_file).run
    MonthLoader.new(      @db, @start_day, @finish_day).run
    PathSummaryLoader.new(@db, @start_day, @finish_day).run
    LaunchLoader.new(@db, @launch_list).run
  end

  def reload_launches
    ensure_db_conn
    LaunchLoader.new(@db, @launch_list).run
  end

  def ensure_db_conn
    return if @db
    @db = DataGateway.new @db_file
  end

  def last_download_date
    raw_files = Dir[@raw_data_dir + '*']
    return @start_day if raw_files.empty?
    date_str = raw_files.sort.last.split('/')[-1]
    return Date.parse(date_str)
  end

  def yesterday
    Date.today - 1
  end

  def google_up_to_date?
    last_download_date == yesterday
  end
  
  def download_from_google
    return if google_up_to_date?
    MonthlyUniqueVisitorsLoader.new(@profile_id, @auth_token, @monthly_visitors_file,
                                    @start_day..@finish_day).run
    VisitDownloader.new(@profile_id, @auth_token, @raw_visits_file, 
                        @start_day..@finish_day).run
    log "downloading from google since #{@last_download_date}"
    Dir.mkdir(@raw_data_dir) unless File.exist? @raw_data_dir
    downloader = PageviewDownloader.new(@profile_id, @auth_token, @raw_data_dir)
    @refresh_date_range.each {|d| downloader.get(d)}
  end


  #tmp = only for temp running
  def mvis
    ensure_db_conn
    MonthVisitsLoader.new(@db, @start_day, @finish_day, @monthly_visitors_file).run
  end

end
