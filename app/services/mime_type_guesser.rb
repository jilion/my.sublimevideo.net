class MimeTypeGuesser
  DEFAULT_RESPONSE = { 'content-type' => 'invalid' }

  def self.guess(url)
    head(url)['content-type']
  end

  private

  def self.head(uri_str)
    uri  = URI.parse(URI.escape(uri_str))
    opts = { use_ssl: uri.scheme == 'https', read_timeout: 3 }

    response = Net::HTTP.start(uri.host, uri.port, opts) do |http|
      http.head(uri.path)
    end

    case response
    when Net::HTTPSuccess, Net::HTTPRedirection
      response
    else
      DEFAULT_RESPONSE
    end
  rescue => ex
    DEFAULT_RESPONSE
  end
end
