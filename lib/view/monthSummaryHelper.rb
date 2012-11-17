require 'erb'

class MonthSummaryHelper
  attr_reader :visitors, :visits, :views, :medianVisits, :medianViews
  def initialize db, month
    @db = db
    @month = month
  end
  def run
    calculate_values
    template = ERB.new(File.read('views/monthSummary.md.erb'))
    return template.result(binding)
  end
  def dateStr
    @month.pretty_str
  end

  def calculate_values
    stmt = "select * from monthVisits where year = :year and month = :month"
    row = @db.get_first_row(stmt, :year => @month.year, :month => @month.month)
    @visitors = thousands_sep row["uniqueVisitors"]
    @visits = thousands_sep row["totalVisits"]
    @views = thousands_sep row["totalViews"]
    @medianVisits = thousands_sep row["medianVisits"]
    @medianViews = thousands_sep row["medianViews"]
  end

  def pages_over aNumber
    stmt = "select count(*) from monthViews where " +
      "month = :month and year = :year and total > :threshold"
    @db.get_first_value(stmt, :month => @month.month, :year => @month.year, :threshold => aNumber)
  end

  def thousands_sep arg
    arg.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
