require 'json'

class Result
  attr_reader :path, :views, :hostname
  def initialize anArray
    @path = anArray[0]
    @hostname = anArray[1]
    @views = anArray[2].to_i
  end
  def to_s
    "%s %s" % [@hostname, @path]
  end
end


data = JSON.parse(File.read('raw-data/2012-05-01'))
rows =  data["rows"].map {|r| Result.new(r)}
#rows.sort_by{|r| r.views}.each {|r| puts r}
puts rows.size
bad = rows.reject{|r| ('martinfowler.com' == r.hostname) or ('www.martinfowler.com' == r.hostname)}
puts bad.size
puts bad






