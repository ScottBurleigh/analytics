require 'stringio'
require 'builder'

class MonthlyHistory
  def initialize db
    @db = db
    @out = StringIO.new
    @xml = Builder::XmlMarkup.new(:target=>@out, :indent=>2)
  end
  def get_data
    rs = @db.execute("select * from monthVisits  " +
                   "order by year, month")
    #@xml.p rs[0].keys.inspect
    return rs    
  end
  def render
    @xml.div(:class => 'recent-top') do
      @table = get_data
      TableRenderer.new(@table, @out).
        columns('year', 'month', 'medianVisits', 'totalVisits', 'uniqueVisitors', 'totalViews', 'medianViews').
        render      
    end
    return @out.string
  end
end
