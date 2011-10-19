# coding: utf-8
require 'digest/md5'

class Ticket
  include ActiveModel::Validations

  attr_accessor :user, :type, :site_token, :subject, :message

  validates :user,    :presence => true
  validates :subject, :presence => true
  validates :message, :presence => true

  validate :user_can_send_ticket

  def self.post_ticket(ticket)
    response  = Zendesk.post("/tickets.xml", ticket.to_xml)
    ticket_id = response['location'][%r{#{Zendesk.base_url}/tickets/(\d+)\.xml}, 1].to_i
    raise "Can't find ticket at: #{response['location']}!" if ticket_id.blank?

    if !ticket.user.zendesk_id? &&
      zendesk_requester_id = JSON[Zendesk.get("/tickets/#{ticket_id}.json").body]["requester_id"].to_i
      ticket.user.update_attribute(:zendesk_id, zendesk_requester_id)
      Ticket.delay(:priority => 25).verify_user(ticket.user.id)
    end

    ticket_id
  end

  def self.verify_user(user_id)
    if user = User.find(user_id)
      Zendesk.put("/users/#{user.zendesk_id}.xml", "<user><password>#{Digest::MD5.new(Time.now.to_s)}</password><is-verified>true</is-verified></user>")
    end
  end

  def initialize(params = {})
    @user    = User.where(id: params.delete(:user_id)).first || nil if params.key?(:user_id)
    @site    = Site.where(token: params.delete(:site_token)).first || nil if params.key?(:site_token)
    @subject = h(params.delete(:subject).try(:to_s))
    @message = message_with_site(params.delete(:message))
  end

  def save
    valid? && Ticket.delay(priority: 25).post_ticket(self)
  end

  def to_key
    nil
  end

  def to_xml(options = {})
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.ticket do
      xml.tag!(:subject, @subject)
      xml.tag!(:description, @message)
      xml.tag!(:"set-tags", @user.support) if @user.support == 'vip'
      if @user.zendesk_id?
        xml.tag!(:"requester-id", @user.zendesk_id)
      else
        xml.tag!(:"requester-name", h(@user.full_name))
        xml.tag!(:"requester-email", h(@user.email))
      end
    end
  end

  private

  def user_can_send_ticket
    if @user && @user.support != 'email'
      self.errors.add(:base, "You can't send new tickets!")
    end
  end

  def message_with_site(message)
    @message = @site ? "Request for site: (#{@site.token}) #{@site.hostname}\n\n" : ''
    @message += h(message.try(:to_s))
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

