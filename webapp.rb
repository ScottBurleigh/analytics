$: << 'lib'
require 'kramdown'

require 'view/recentTops'
require 'dataGateway'
require 'view/visitHistory'
require 'view/launchesList'
require 'view/tableRenderer'
require 'view/monthlyHistory'
require 'view/monthSummaryHelper'
require 'month'

enable :show_exceptions 

$db ||= DataGateway.new 'data/data.db'

get '/' do
  haml :index
end

get '/launches' do
  haml :launches
end

get '/launches-d3' do
  haml :launches_d3
end

get '/month-history' do
  haml :month_history
end

get '/help' do
 haml :help
end

get '/css/analytics.css' do
  scss :'css/analytics'
end

get '/css/launch-d3.css' do
  scss :'css/launch-d3'
end

error do
  "oops: <br>" + env['sinatra.error'].message
end
