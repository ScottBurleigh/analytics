class TestDB
  # having problems managing and closing db connections for testing
  # cannot close db connection without finalizing prepared statments, but
  # can't find API for finalizing them. So using single db connection and relying 
  # on process termination to close it


  attr_reader :conn, :full_conn
  def initialize
    @conn = SQLite3::Database.open 'test/test.db'
    @conn.results_as_hash = true
    @full_conn = SQLite3::Database.open 'test/data/data.db'
    @full_conn.results_as_hash = true
  end
	@@instance = self.new
	def self.method_missing name, *args
		@@instance.send name, *args
	end
end
 
