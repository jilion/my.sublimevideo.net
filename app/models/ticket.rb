# coding: utf-8
require 'digest/md5'

class Ticket
  include ActiveModel::Validations

  attr_accessor :user, :type, :site_token, :subject, :message

  # EMAIL_SUPPORT_ALLOWED_TYPES = %w[integration other]

  validates :user,    :presence => true
  # validates :type,    :inclusion => { :in => Ticket::EMAIL_SUPPORT_ALLOWED_TYPES, :message => "You must choose a category" }
  validates :subject, :presence => true
  validates :message, :presence => true

  validate :user_can_send_ticket

  def self.post_ticket(data={})
    ticket    = Ticket.new(data)
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

  def initialize(params={})
    @user    = User.where(id: params.delete(:user_id)).first || nil if params.key?(:user_id)
    # @type    = params.delete(:type)
    @site    = Site.where(token: params.delete(:site_token)).first || nil if params.key?(:site_token)
    @subject = h(params.delete(:subject).try(:to_s))
    @message = message_with_site(params.delete(:message))
  end

  def save
    valid? && Ticket.delay(priority: 25).post_ticket(self.to_hash)
  end

  def to_key
    nil
  end

  def to_hash
    { user_id: @user.id, type: @type, site: @site ? @site.hostname : 'no site', subject: @subject, message: @message }
  end

  def to_xml(options={})
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.ticket do
      xml.tag!(:subject, @subject)
      xml.tag!(:description, @message)
      # xml.tag!(:"set-tags", @type)
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
    # if @user && @type && @user.support != 'email'
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

