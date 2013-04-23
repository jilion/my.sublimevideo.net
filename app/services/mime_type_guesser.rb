class MimeTypeGuesser
  def self.guess(url)
    head(url)['content-type']
  end

  private

  def self.head(uri_str)
    default_response = { 'content-type' => 'invalid' }
    uri  = URI.parse(URI.escape(uri_str))
    opts = { use_ssl: uri.scheme == 'https', read_timeout: 3 }
    default_response = { 'content-type' => 'invalid' }

    response = Net::HTTP.start(uri.host, uri.port, opts) do |http|
      http.head(uri.path)
    end

    case response
    when Net::HTTPSuccess, Net::HTTPRedirection
      response
    else
      default_response
    end
  rescue => ex
    default_response
  end
end
