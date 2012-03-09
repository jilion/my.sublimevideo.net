module MimeTypeGuesser

  def self.guess(url)
    self.head(url)['content-type']
  end

private

  def self.head(uri_str)
    uri = URI.parse(uri_str)

    response = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(Net::HTTP::Head.new(uri.path))
    end

    case response
    when Net::HTTPSuccess
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
