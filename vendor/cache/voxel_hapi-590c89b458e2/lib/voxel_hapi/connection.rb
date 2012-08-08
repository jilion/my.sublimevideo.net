require 'net/https'
require 'uri'

class Net_HTTP < Net::HTTP
  def initialize(*args)
    super
    @ssl_context = OpenSSL::SSL::SSLContext.new
    @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
end

class VoxelHAPIConnection
  USER_AGENT = 'Voxel hAPI ruby Client; 1.0'
  
  exceptions :argument, :backend
  
  attr_accessor :debug
  attr_accessor :hapi_hostname
  attr_accessor :hapi_version
  
  def initialize( options = {} )
    options.reverse_merge! :debug => false, :hapi_hostname => 'api.voxel.net',
    :hapi_version => '1.0'
    
    @hapi_hostname	= options[:hapi_hostname]
    @hapi_version   = options[:hapi_version]
    @debug          = options[:debug]
  end
  
  def call_method( request, auth_info = {} )
    raise Argument, "You must pass a VoxelHAPIRequest object to VoxelHAPIConnection#call_method" unless request.is_a?(VoxelHAPIRequest)
    
    response = make_http_request( URI.parse("https://#{@hapi_hostname}#{api_path}"), request.request_options, auth_info )
    
    case response
    when Net::HTTPSuccess, Net::HTTPRedirection
      puts response.body if @debug
      VoxelHAPIResponse.new :raw_xml => response.body, :debug => @debug
    when Net::HTTPUnauthorized
      STDERR.puts response.class.to_s if @debug
      raise Backend, "Invalid Username or Password"
    else
      STDERR.puts response.class.to_s if @debug
      raise Backend, "Invalid response code from API endpoint"
    end
  end
  
  def api_path
    case @hapi_version
    when "current", "beta"
      "/#{@hapi_version}/"
    else
      "/version/#{@hapi_version}/"
    end
  end
  
  private
  
  # POST a request to a given url with supplied options
  # will automatically retry 3 times before giving up
  def make_http_request( url, options, auth_info = {} )
    try_count = 0
    
    begin
      request = Net::HTTP::Post.new(url.path)
      request.basic_auth auth_info[:hapi_username], auth_info[:hapi_password] unless auth_info.empty?
      request.set_form_data(options)
      request.add_field('User-Agent', USER_AGENT)
      
      http = Net_HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.request(request)
    rescue Errno::ECONNREFUSED
      if try_count < 2
        try_count += 1
        sleep 1
        retry
      else
        raise Backend, "Connection refused trying to contact hAPI at #{@hapi_hostname}"
      end
    end
  end
end