module GoogleDownloading
  def assert_no_error json
    data = JSON.parse(json)
    raise GoogleDownloadException.new(data) if data.has_key? 'error'
  end

  class GoogleDownloadException < Exception
    def initialize responseHash
      @data = responseHash
    end
    def to_s
      "Error downloading data from google: %s (%s)" % [error_message, code]
    end
    def error_data
      @data['error']
    end
    def error_message
      error_data['message']
    end
    def code
      error_data['code']
    end
  end
end
