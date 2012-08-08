require 'time'
require 'digest/md5'

class VoxelHAPIRequest
  exceptions :argument, :backend
  
  attr_accessor :debug
  attr_accessor :method
  attr_accessor :param
  attr_accessor :hapi_username
  attr_accessor :hapi_password
  attr_reader   :hapi_authkey
  
  def initialize( options = {} )
    options.reverse_merge! :debug => false, :param => {}, :hapi_authkey => {}
    
    raise Argument, ":method is a required option." unless options.has_key?(:method)
    raise Argument, ":param is a hash of key/value pairs" unless options.is_a?(Hash)
    
    @method         = options[:method]
    @param          = options[:param]
    @hapi_username  = options[:hapi_username]
    @hapi_password  = options[:hapi_password]
    @hapi_authkey   = options[:hapi_authkey]
    @debug          = options[:debug]
  end
  
  def request_options
    if @param.nil?
      options = {}
    else
      options = @param.clone
    end
    
    options[:method]    = @method
    options[:timestamp] = Time.now.xmlschema
    
    if @hapi_authkey.empty?
      options[:user]      = @hapi_username
    else
      options[:key]      = @hapi_authkey['key']
    end
    
    options[:api_sig]   = generate_signature(options)
    options
  end
  
private
  
  def generate_signature(options)
    if @hapi_authkey.empty?
      signature = @hapi_password + options.keys.map { |k| k.to_s }.sort.map { |k| "#{k}#{options[k.to_sym]}" }.join("")
    else
      signature = @hapi_authkey['secret'] + options.keys.map { |k| k.to_s }.sort.map { |k| "#{k}#{options[k.to_sym]}" }.join("")
    end
    
    Digest::MD5.hexdigest(signature)
  end
end