class FakeURI
  attr_accessor :scheme, :host, :port, :path

  def initialize(url)
    @scheme = /^([htps]+):/.match(url)[1]
    matches = /^https?:\/\/([a-zA-Z0-9_.-]+):?([0-9]+)?\/?(.*)$/.match(url)
    @host = matches[1]
    @port = matches[2].to_i
    @path = matches[3]
  end

  def self.parse(url)
    return FakeURI.new(url)
  end
end