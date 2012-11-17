class PageviewDownloader
  include GoogleDownloading

  def initialize account_id, auth_token, output_dir
    @account_id = account_id
    @auth_token = auth_token
    @output_dir = output_dir
  end
  
  def get day
    cmd_start = %[curl -H "Authorization: GoogleLogin auth=#{@auth_token}"]
    curl_str = 
      "https://www.googleapis.com/analytics/v3/data/ga/" + 
      "?ids=ga:#{@account_id}" +
      "&metrics=ga:uniquePageviews" + 
      "&start-date=#{day}&end-date=#{day}" + 
      "&dimensions=ga:pagePath"
    cmd = %[#{cmd_start} "#{curl_str}"]
    log "downloading for: %s", day
    json = `#{cmd}`
    assert_no_error json
    File.open(@output_dir + day.to_s, 'w') do |out|
      out << json
    end
  end
end
