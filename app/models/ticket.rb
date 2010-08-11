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
    @@unordered_types ||= TYPES.inject({}){ |memo,h| memo.merge!(h) }
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
        :set_tags    => self.class.unordered_types[@type]
      }.merge(user_params)
    })
    if @user.zendesk_id.blank?
      response = Zendesk.get(response['location'].sub(Zendesk.base_url, '').sub('xml', 'json'))
      @user.update_attribute(:zendesk_id, JSON.parse(response.body)["requester_id"].to_i)
    end
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