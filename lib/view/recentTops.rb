require 'stringio'
require 'builder'


class RecentTops
  AMOUNT = 100
  def initialize db
    @db = db
    @out = StringIO.new
    @xml = Builder::XmlMarkup.new(:target=>@out, :indent=>2)
    @latest_month = Month.from_date(Date.today - 1).prev
  end
  def year
    @latest_month.year
  end
  def month 
    @latest_month.month
  end
  def render
    @xml.div(:class => 'recent-top') do
      @table = select_top
      enrich_with_prior_rank
      enrich_with_sparklines
      TableRenderer.new(@table, @out).
        show_rank.
        columns('prior rank', 'path',  'recent_median', 'median', 'median history', 'total').
        render      
    end
    return @out.string
  end

  def select_top
    rs = @db.execute("select * from monthviews  " +
                   "join pathsummaries using (path) " +
                   "join recents using (path) " + 
                   "where year = #{year} and month = #{month} " +
                   "order by recent_median desc limit #{AMOUNT}")
    #@xml.p rs[0].keys.inspect
    return rs
  end
  def enrich_with_prior_rank
    @table.each do |row|
      prior_row = @db.get_monthview(row['path'], row['year'], row['month'])
      if prior_row
        row['prior rank'] = prior_row['rank']
      else
        row['prior median'] = "-"
      end
    end
  end
  def enrich_with_sparklines
    @table.each do |row|
      row['median history'] = "<span class = 'medianSparkline'>" + 
        (row['medianHistory'] || "") + "</span>"
    end
  end
  def gain this, prior
    return "" if 0 == prior
    value = this * 100.0 / prior
    return "%2d%%" % value
  end

end
