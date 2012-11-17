require 'highline/import'
require 'yaml'

class AuthorizationTokenLoader
  def initialize data_dir
    @data_dir = data_dir
  end
  
  def run
    retrieve_raw_auth
    #save_raw
    #load_raw
    save
  end

  def retrieve_raw_auth
    config = YAML::load(File.read(@data_dir + 'config.yaml'))
    email = config['auth_email'].strip
    password = ask("google password:  ") { |q| q.echo = false }
    auth_cmd = "curl https://www.google.com/accounts/ClientLogin --data-urlencode Email=#{email} --data-urlencode Passwd=#{password} -d service=analytics"
    @raw_auth = `#{auth_cmd}`
  end

  def save
    File.open(@data_dir + 'auth-token', 'w') {|f| f <<  @raw_auth.split("\n")[2][5..-1].chomp}
  end


  # these methods only used during development/debugging to save accessing google
  def save_raw
    File.open('raw-auth', 'w') {|f| f << @raw_auth}
  end
  def load_raw
    @raw_auth = File.read('raw-auth')
  end

end

