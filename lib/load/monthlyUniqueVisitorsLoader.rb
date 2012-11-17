class MonthlyUniqueVisitorsLoader
  include GoogleDownloading

  def initialize account_id, auth_token, output_file, date_range
    @account_id = account_id
    @auth_token = auth_token
    @output_file = output_file
    @date_range = date_range
  end
  def run
    cmd_start = %[curl -H "Authorization: GoogleLogin auth=#{@auth_token}"]
    curl_str = "https://www.googleapis.com/analytics/v3/data/ga/" + 
      "?ids=ga:#{@account_id}" +
      "&metrics=ga:visitors" +
      "&dimensions=ga:month,ga:year" +
      "&start-date=#{@date_range.first}&end-date=#{@date_range.last}"
    cmd = %[#{cmd_start} "#{curl_str}"]
    log "downloading monthly visitors"
    json = `#{cmd}`
    assert_no_error json
    File.open(@output_file, 'w') do |out|
      out << json
    end
  end
end
