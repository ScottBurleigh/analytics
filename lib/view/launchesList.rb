class LaunchesList
  def initialize db
    @db = db
    @out = StringIO.new
    @xml = Builder::XmlMarkup.new(:target=>@out, :indent=>2)
  end
  def render
   @xml.div(:class => 'launches') do
      @table = select_launches
      #enrich_with_sparklines
      enrich_with_plot_commands
      # @xml << @table.inspect
      TableRenderer.new(@table, @out).
        columns('path', 'plot', 'date', 'total_7_days', 
                'total_28_days', 'peak_day', 'recent_median').#, 'history').
        render      
    end
    return @out.string
   end
  def select_launches
    rs = @db.execute("SELECT * FROM launches  ORDER BY date DESC")
    return rs
  end
  def enrich_with_sparklines
    @table.each do |row|
      row['history'] = "<span class = 'sparkline-20d'>" + 
        row['history'].to_s + "</span>"
    end
  end
  def enrich_with_plot_commands
    @table.each do |row|
      row['plot'] = "<span class = 'plot' data-path = '#{row['path']}'>plot</span>" 
    end
  end
end

