# The library provides the class HAPI, a ruby interface to Voxel's hAPI
# http://api.voxel.net/docs
#
# Author::    James W. Brinkerhoff  (mailto:jwb@voxel.net)
# Copyright:: Copyright (c) 2009 Voxel dot Net, Inc.
# License::   Unknown

require 'voxel_hapi/exceptions'
require 'voxel_hapi/connection'
require 'voxel_hapi/request'
require 'voxel_hapi/response'

class VoxelHAPI
  exceptions :argument, :backend
  
  #API Username
  attr_accessor :hapi_username
  #API Password
  attr_accessor :hapi_password
  #API Host, Defaults to api.voxel.net
  attr_accessor :hapi_hostname
  #API Endpoint Version, Defaults to '1.0'
  attr_accessor :hapi_version
  #Debug Mode, When true outputs debugging info via STDERR
  attr_accessor :debug
  #Holds the active hAPI Connection object
  attr_reader :connection
  #Holds the hAPI authkey
  attr_accessor :hapi_authkey
  
  def initialize(options = {})
    options.reverse_merge! :hapi_hostname => 'api.voxel.net', :debug => false,
    :hapi_version => '1.0', :hapi_authkey => {}
    
    if options[:hapi_authkey].empty?
      validate_required_options options, :hapi_username, :hapi_password
    else
      validate_required_options options[:hapi_authkey], :key, :secret
    end
    
    @hapi_username  = options[:hapi_username]
    @hapi_password  = options[:hapi_password]
    @hapi_hostname  = options[:hapi_hostname]
    @hapi_version   = options[:hapi_version]
    @debug          = options[:debug]
    @hapi_authkey   = options[:hapi_authkey]
    
    begin
      @connection = VoxelHAPIConnection.new :hapi_hostname => @hapi_hostname, :hapi_version => @hapi_version, :debug => @debug
      
      if @hapi_authkey.empty?
        @hapi_authkey = voxel_hapi_authkeys_read
      else
        options[:hapi_authkey].dup.each_key do |key|
          @hapi_authkey[key.to_s] = options[:hapi_authkey][key]
        end
      end
    rescue Exception => ex
      raise Backend, ex.message
    end
  end
  
  def voxel_hapi_authkeys_read( options = {}, output_options = {} )
    request_method( 'voxel.hapi.authkeys.read', options, true )['authkey']
  end
  
  def voxel_devices_list( options = {}, output_options = {} )
    options.reverse_merge! :verbosity => 'compact'
    response = request_method( 'voxel.devices.list', options )
    
    handle_parsed_xml( response['devices']['device'] )
  end
  
  def voxel_images_list( options = {}, output_options = {} )
    options.reverse_merge! :verbosity => 'compact'
    request_method( 'voxel.images.list', options )['images']['image']
  end
  
  def voxel_voxservers_facilities_list( options = {}, output_options = {} )
    facilites = request_method( 'voxel.voxservers.facilities.list', options )['facilities']['facility']
    handle_parsed_xml( facilites )
  end
  
  def voxel_voxservers_inventory_list( options = {}, output_options = {} )
    options.reverse_merge! :verbosity => 'compact'
    facilites = request_method( 'voxel.voxservers.inventory.list', options )['facilities']['facility']
    handle_parsed_xml( facilites )
  end
  
  def voxel_voxservers_create( options = {}, output_options = {} )
    request_method( 'voxel.voxservers.create', options )['device']
  end
  
  def voxel_voxservers_status( options = {}, output_options = {} )
    options.reverse_merge! :verbosity => 'compact'
    request_method( 'voxel.voxservers.status', options )['devices']['device']
  end
  
  def voxel_voxcloud_status( options = {}, output_options = {} )
    options.reverse_merge! :verbosity => 'compact'
    request_method( 'voxel.voxcloud.status', options )['devices']['device']
  end
  
  def voxel_voxcloud_create( options = {}, output_options = {} )
    request_method( 'voxel.voxcloud.create', options )['device']
  end
  
  def voxel_voxcloud_clone( options = {}, output_options = {} )
    request_method( 'voxel.voxcloud.clone', options )['device']
  end
  
  def voxel_hapi_version( options = {}, output_options = {} )
    options.reverse_merge! :verbosity => 'compact'
    request_method( 'voxel.hapi.version', options )
  end
  
  # CDN
  def voxel_voxcast_ondemand_content_purge_directory( options = {}, output_options = {} )
    options.reverse_merge! :verbosity => 'compact'
    request_method( 'voxel.voxcast.ondemand.content.purge_directory', options )
  end
  
  def voxel_voxcast_ondemand_content_purge_file( options = {}, output_options = {} )
    options.reverse_merge! :verbosity => 'compact'
    request_method( 'voxel.voxcast.ondemand.content.purge_file', options )
  end
  
  def voxel_voxcast_ondemand_content_purge_site( options = {}, output_options = {} )
    options.reverse_merge! :verbosity => 'compact'
    request_method( 'voxel.voxcast.ondemand.content.purge_site', options )
  end
  
  def voxel_voxcast_ondemand_content_transaction_status( options = {}, output_options = {} )
    options.reverse_merge! :verbosity => 'compact'
    request_method( 'voxel.voxcast.ondemand.content.transaction_status', options )
  end
  
  def voxel_voxcast_ondemand_testing_get_url_per_pop( options = {}, output_options = {} )
    options.reverse_merge! :verbosity => 'compact'
    request_method( 'voxel.voxcast.ondemand.testing.get_url_per_pop', options )
  end
  
private
  
  def handle_parsed_xml( xmldata )
    if xmldata.nil?
      []
    elsif xmldata.is_a?(Hash)
      [ xmldata ]      
    else
      xmldata
    end
  end
  
  def request_method( method_name, options = {}, use_auth = false, xml_options = {}, output_options = {} )
    output_options.reverse_merge! :format => :ruby
    
    begin
      request = VoxelHAPIRequest.new :hapi_username => @hapi_username,
      :hapi_password => @hapi_password, :method => method_name,
      :param => options, :debug => @debug, :auth_version => @hapi_version,
      :hapi_authkey => @hapi_authkey
      
      if use_auth
        response = @connection.call_method(request, {
        :hapi_username => @hapi_username, :hapi_password => @hapi_password })
      else
        response = @connection.call_method(request)
      end
      
      raise Backend, response.to_h['err']['msg'] if response.to_h['stat'] == "fail"
      
      case output_options[:format]
      when :ruby
        response.to_h(xml_options)
      when :xml
        response.to_xml
      end
    rescue VoxelHAPIConnection::Error => ex
      raise ex, ex.message
    end
  end
  
  def method_missing( method_id, *args )
    method_name = method_id.id2name
    method_name_parts = []
    method_name.split("_").each do |mpart|
      method_name_parts << mpart.underscore
    end
    method_name = method_name_parts.join(".")
    
    STDERR.puts "auto-handling #{method_name}" if @debug
    
    if args.length > 1
      request_method method_name, args[0], false, {}, args[1]
    else
      request_method method_name, args[0], false, {}
    end
  end
  
  def validate_required_options( all, *required )
    required.each do |opt|
      raise Argument, ":#{opt} must be specified" unless all.has_key?(opt)
      raise Argument, ":#{opt} must be non-NULL"  if all[opt].nil?
    end
  end
end