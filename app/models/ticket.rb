# == Schema Information
#
#  type            :integer   not null
#  subject         :string    not null
#  description     :text      not null
#  requester_name  :string
#  requester_email :string
#

class Ticket
  include ActiveModel::Validations
  
  attr_accessor :type, :subject, :description, :requester_name, :requester_email
  
  TYPES = [
    { :signup => 'signup' },
    { :request => 'request' },
    { :billing => 'billing' },
    { :confused => 'confused' },
    { :broken => 'broken' },
    { :other => 'other' },
  ]
  
  def self.ordered_types
    TYPES
  end
  
  def self.unordered_types
    @@unordered_types = TYPES.inject({}){ |memo,h| memo.merge!(h) }
  end
  
  validates :type,            :inclusion => { :in => Ticket.unordered_types.keys }
  validates :subject,         :presence => true
  validates :description,     :presence => true
  validates :requester_name,  :presence => true
  validates :requester_email, :presence => true
  
  def initialize(user = nil, params = {})
    @type        = params.delete(:type)
    @subject     = params.delete(:subject)
    @description = params.delete(:description)
    if user.present?
      @requester_name  = user.full_name
      @requester_email = user.email
    end
  end
  
  def save
    Rails.logger.info "Saving the ticket..."
    valid?
  end
  
  def to_key
    nil
  end
  
end


# require 'rubygems'
# require 'curb'
# require 'json'
# 
# USERNAME = "zeno@jilion.com"
# PASSWORD = "wrank8"
# 
# 
# curl = Curl::Easy.new("http://jilion.zendesk.com/tickets.xml") do |c|
#   c.userpwd = "#{USERNAME}:#{PASSWORD}"
#   c.headers = "Content-Type: application/xml"
# end
# body = "<ticket><subject>Billing problem</subject><description>I have a problem with the billing, it's too expensive</description><requester-name>Rémy Coutable</requester-name><requester-email>remy@jilion.com</requester-email><set-tags>billing</set-tags></ticket>"
# curl.http_post(body)
# 
# puts curl.response_code
# puts
# puts curl.body_str
# puts
# puts curl.header_str
# 
# headers = {}
# unless curl.header_str.nil? || curl.header_str == ""
#   curl.header_str.split("\r\n")[1..-1].each do |h|
#     m = h.match(/([^:]+):\s?(.*)/)
#     next if m.nil? or m[2].nil?
#     headers[m[1]] = m[2]
#   end
# end
# 
# puts headers["Location"]
# 
# curl = Curl::Easy.new(headers["Location"].sub('xml', 'json')) do |c|
#   c.userpwd = "#{USERNAME}:#{PASSWORD}"
# end
# curl.perform
# 
# puts
# puts JSON.parse(curl.body_str)["requester_id"]
# 
# # curl -u zeno@jilion.com:wrank8 http://jilion.zendesk.com/tickets.xml
# # curl -u zeno@jilion.com:wrank8 -H "Content-Type: application/xml" -d "<ticket><subject>Billing problem</subject><description>I have a problem with the billing, it's too expensive</description><requester-name>Rémy Coutable</requester-name><requester-email>remy@jilion.com</requester-email><set-tags>billing</set-tags></ticket>" -X POST http://jilion.zendesk.com/tickets.xml