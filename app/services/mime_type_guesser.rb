class MimeTypeGuesser

  def self.guess(url)
    head(url)['content-type']
  end

  private

  def self.head(uri_str)
    uri  = URI.parse(uri_str)
    opts = { use_ssl: uri.scheme == 'https', read_timeout: 3 }

    response = Net::HTTP.start(uri.host, uri.port, opts) do |http|
      http.head(uri.path)
    end

    case response
    when Net::HTTPSuccess, Net::HTTPRedirection
      response
    when Net::HTTPClientError
      { 'content-type' => "4" }
    else
      { 'content-type' => "" }
    end
  rescue => ex
    { 'content-type' => "4" }
  end
end
