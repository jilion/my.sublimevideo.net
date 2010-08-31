# == Schema Information
#
#  type            :integer   not null
#  subject         :string    not null
#  description     :text      not null
#  requester_name  :string
#  requester_email :string
#
require 'md5'

class Ticket
  include ActiveModel::Validations
  
  attr_accessor :user, :type, :subject, :description
  
  TYPES = [
    { :request => 'request' },
    { :billing => 'billing' },
    { :confused => 'confused' },
    { :broken => 'broken' },
    { :other => 'other' },
  ]
  
  def self.ordered_types
    @@ordered_types ||= if MySublimeVideo::Release.beta?
      TYPES.dup.tap { |t| t.delete(t.select { |x| x.key?(:billing) }[0]) }
    else
      TYPES
    end
  end
  
  def self.unordered_types
    @@unordered_types ||= ordered_types.inject({}) { |memo,h| memo.merge!(h) }
  end
  
  validates :user,        :presence => true
  validates :type,        :inclusion => { :in => Ticket.unordered_types.keys, :message => "You must choose a category!" }
  validates :subject,     :presence => true
  validates :description, :presence => true
  
  def initialize(params = {})
    @user        = params.delete(:user)
    @type        = params.delete(:type).try(:to_sym)
    @subject     = h(params.delete(:subject).try(:to_s))
    @description = h(params.delete(:description).try(:to_s))
  end
  
  def save
    if valid? && delay_post_ticket
      true
    else
      false
    end
  end
  
  def post_ticket
    response = Zendesk.post("/tickets.xml", {
      :ticket => {
        :subject     => @subject,
        :description => @description,
        :set_tags    => Ticket.unordered_types[@type]
      }.merge(user_params)
    })
    ticket_id = response['location'].match(%r(#{Zendesk.base_url}/tickets/(\d+)\.xml))[1].to_i
    raise "Can't find ticket at: #{response['location']}!" if ticket_id.blank?
    
    if @user.zendesk_id.blank?
      zendesk_requester_id = JSON.parse(Zendesk.get("/tickets/#{ticket_id}.json").body)["requester_id"].to_i
      if zendesk_requester_id
        @user.update_attribute(:zendesk_id, zendesk_requester_id)
        delay_verify_user
      end
    end
    ticket_id
  end
  
  def verify_user
    Zendesk.put("/users/#{@user.zendesk_id}.xml", :user => { :password => MD5.new(Time.now.to_s).to_s, :is_verified => true })
  end
  
  def to_key
    nil
  end
  
private
  
  def delay_post_ticket
    delay(:priority => 25).post_ticket
  end
  
  def delay_verify_user
    delay(:priority => 25).verify_user
  end
  
  def user_params
    if @user.zendesk_id.present?
      { :requester_id => @user.zendesk_id }
    else
      { :requester_name => @user.full_name, :requester_email => @user.email }
    end
  end
  
end