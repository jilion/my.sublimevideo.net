# coding: utf-8

require 'digest/md5'

class Ticket
  include ActiveModel::Validations

  attr_accessor :user, :type, :subject, :message

  TYPES = %w[integration idea bug billing other]

  validates :user,    :presence => true
  validates :type,    :inclusion => { :in => Ticket::TYPES, :message => "You must choose a category" }
  validates :subject, :presence => true
  validates :message, :presence => true

  def initialize(params = {})
    @user    = params.delete(:user)
    @type    = params.delete(:type)
    @subject = h(params.delete(:subject).try(:to_s))
    @message = h(params.delete(:message).try(:to_s))
  end

  def save
    valid? && delay(:priority => 25).post_ticket
  end

  def post_ticket
    response = Zendesk.post("/tickets.xml", {
      :ticket => {
        :subject     => @subject,
        :description => @message,
        :set_tags    => "#{@type} #{@user.support}-support"
      }.merge(user_params)
    })
    ticket_id = response['location'].match(%r(#{Zendesk.base_url}/tickets/(\d+)\.xml))[1].to_i
    raise "Can't find ticket at: #{response['location']}!" if ticket_id.blank?

    if @user.zendesk_id.blank? && zendesk_requester_id = JSON.parse(Zendesk.get("/tickets/#{ticket_id}.json").body)["requester_id"].to_i
      @user.update_attribute(:zendesk_id, zendesk_requester_id)
      delay(:priority => 25).verify_user
    end

    ticket_id
  end

  def verify_user
    Zendesk.put("/users/#{@user.zendesk_id}.xml", :user => { :password => Digest::MD5.new(Time.now.to_s).to_s, :is_verified => true })
  end

  def to_key
    nil
  end

private

  def user_params
    if @user.zendesk_id.present?
      { :requester_id => @user.zendesk_id }
    else
      { :requester_name => @user.full_name, :requester_email => @user.email }
    end
  end

end


# == Schema Information
#
#  type            :integer   not null
#  subject         :string    not null
#  message         :text      not null
#  requester_name  :string
#  requester_email :string
#

