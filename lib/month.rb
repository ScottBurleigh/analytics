require 'date'
class Month
  attr_reader :year, :month
  def initialize year, month
    @year = year
    @month = month
  end
  def succ
    return (12 == month) ? Month.new(year + 1, 1) : Month.new(year, month + 1)
  end
  def prev
    return (1 == month) ? Month.new(year - 1, 12) : Month.new(year, month - 1)
  end
  def self.from_date date
    raise ArgumentError unless date
    raise ArgumentError unless date.kind_of? Date
    self.new(date.year, date.month)
  end
  def self.range start, finish
    return Month.from_date(start)..Month.from_date(finish)
  end
  def self.last
    self.from_date(Date.today).prev
  end
  def ord
    return year * 12 + month
  end
  def <=> other
    return ord <=> other.ord
  end
  def to_s
    "%s-%s" % [year, month]
  end
  def to_binding
    {:month => "%02d" % month, :year => "%s" % year}
  end
  def name
    Date::ABBR_MONTHNAMES[@month]
  end
  def monthStr
    "%02d" % month
  end
  def pretty_str
    d = Date.new(year, month, 1)
    return d.strftime("%B %Y")
  end
end
