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
      TYPES.dup.tap { |t| t.delete_at(t.index(t.select{ |x| x.key?(:billing) }[0])) }
    else
      TYPES
    end
  end
  
  def self.unordered_types
    @@unordered_types ||= ordered_types.inject({}){ |memo,h| memo.merge!(h) }
  end
  
  validates :user,        :presence => true
  validates :type,        :inclusion => { :in => Ticket.unordered_types.keys }
  validates :subject,     :presence => true
  validates :description, :presence => true
  
  def initialize(params = {})
    @user        = params.delete(:user)
    @type        = params.delete(:type).try(:to_sym)
    @subject     = params.delete(:subject).try(:to_s)
    @description = params.delete(:description).try(:to_s)
  end
  
  def save
    if valid? && delay_post_ticket
      true
    else
      false
    end
  end
  
  def post_ticket
    response = Zendesk.post("/tickets.xml",
    {
      :ticket => {
        :subject     => @subject,
        :description => @description,
        :set_tags    => Ticket.unordered_types[@type]
      }.merge(user_params)
    })
    ticket_id = response['location'].match(%r(#{Zendesk.base_url}/tickets/(\d+)\.xml))[1].to_i
    
    if @user.zendesk_id.blank?
      res = Zendesk.get("/tickets/#{ticket_id}.json")
      @user.update_attribute(:zendesk_id, JSON.parse(res.body)["requester_id"].to_i)
    end
    ticket_id # id of the created ticket
  end
  
  def to_key
    nil
  end
  
private
  
  def delay_post_ticket
    delay(:priority => 25).post_ticket
  end
  
  def user_params
    if @user.zendesk_id.present?
      { :requester_id => @user.zendesk_id }
    else
      { :requester_name => @user.full_name, :requester_email => @user.email }
    end
  end
  
end