require 'erb'
require 'stringio'

class VisitHistory
  def initialize db
    @db = db
  end
  def data
    # totalVisits = query_data.map do |row|
    #   "['%s-%s-01',%s]" % [row['year'], row['month'], row['totalVisits']]
    # end
    medianVisits = query_data.
      select{|r| r['medianVisits']}.
      map do |row|
        "['%s-%s-01',%s]" % [row['year'], row['month'], row['medianVisits']]
      end
    return "[[#{medianVisits.join(',')}]]"
  end
  def message
    msg = data.inspect
    "<p>#{msg}</p>"
  end

  
  
  def query_data
    return @db.execute "select totalVisits, medianVisits, year, month from monthVisits "  
  end


  def render
    out = StringIO.new
    out << 
      "<script type='text/javascript'>\n" <<
      ERB.new(File.read('visitHistory.js')).result(binding) <<
      "\n</script>"
    return out.string
  end
  
  
end
