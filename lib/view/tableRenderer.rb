class TableRenderer
  #methods to render a table represented as an array of hashes

  def initialize table, out_stream
    @table = table
    @out = out_stream
    @xml = Builder::XmlMarkup.new(:target=>@out, :indent=>2)
  end
 
  def render
    raise "no heads" if @columns.empty?
    @xml.table do
      @xml.tr do
        @xml.th(:class => 'table-rank') if @show_rank
        @columns.each do |h|
          @xml.th(:class => selector(h)){@xml << table_head(h)}
        end
      end
      @table.each_with_index do |row, ix|
        @xml.tr do
          @xml.td(:class => 'table-rank') {@xml << ix + 1} if @show_rank
          @columns.each do |key|
            @xml.td(:class => selector(key)) {@xml << row[key]}
          end
        end
      end
    end
  end

  def table_head aColumn
    aColumn.to_s.gsub("_", " ")
  end

  def selector aString
    aString.gsub " ", "-"
  end

  def show_rank
    @show_rank = true
    return self
  end

  def columns *args
    @columns = args.flatten
    self
  end

end
