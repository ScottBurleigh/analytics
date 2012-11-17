require 'fileutils'

class MedianSparklineMaker
  SPARKLINE_DIR = 'img/median-history/'
  def initialize db_gateway, start_date, end_date
    @db = db_gateway
    @start_date = start_date
    @end_date = end_date
  end
  def run
    generate_median_history_sparklines
  end
  def months
    Month.from_date(@start_date)..Month.from_date(@end_date)
  end

  def generate_median_history_sparklines
    log "generating median history sparklines"
    paths = @db.execute("select distinct path from monthviews " +
                                "where median > 10").map{|r| r['path']}
    paths.each {|p| generate_median_history_sparkline_for p}
  end
  def generate_median_history_sparkline_for pathStr
    data = fill_median_history(get_median_history(pathStr)).
      map{|r| r['median']}
    @db.execute("update pathSummaries set medianHistory = :values " +
                "where path = :path ", 
                :path => pathStr, :values => data.join(","))
  end
  def target path
    'public/' + self.class.src(path)
  end
  def self.src path
    SPARKLINE_DIR + path.gsub('/', '-') + '.png'
  end
  def get_median_history pathStr
    result = @db.get_monthviews_for_path pathStr
    return result
  end
  
  def fill_median_history table
    result = fill_missing_months_at_start table
    result = fill_median_history_gaps(result) unless months.count == result.size
    result = remove_last_value_if_zero(result)    
    return result
  end
  def fill_missing_months_at_start table
    first_month = Month.new(table.first['year'], table.first['month'])
    missing_months = months.first..first_month.prev
    additions = missing_months.map do |m|
      {'median' => 0, 'year' => m.year, 'month' => m.month}
    end
    return additions + table
  end
  def fill_median_history_gaps table
    result = table.reverse
    months.to_a.reverse.each_with_index do |m, ix|
     unless row_matches(result[ix], m)
        new_row = {'median' => result[ix]['median'], 
                   'year' => m.year, 'month' => m.month}
        result.insert(ix, new_row)
      end
    end
    return result.reverse    
  end
  def row_matches row, aMonth
    row['month'] == aMonth.month && row['year'] == aMonth.year
  end
  def remove_last_value_if_zero table
    return (0 == table.last['median']) ? table[0..-2] : table
  end
end
