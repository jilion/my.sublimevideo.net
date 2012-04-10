# coding: utf-8
class Ticket
  include ActiveModel::Validations

  attr_accessor :site_token, :type, :subject, :message

  validates :user, :subject, :message, presence: true

  validate :user_can_send_ticket

  def self.post_ticket(params)
    ticket = Ticket.new(params)

    response  = Zendesk.post("/tickets.xml", ticket.to_xml)
    ticket_id = response.location[%r{/tickets/(\d+)\.xml}, 1].to_i

    raise "Can't find ticket at: #{response.location}!" if ticket_id.zero?

    if !ticket.user.zendesk_id? &&
      zendesk_requester_id = Zendesk.get("/tickets/#{ticket_id}.json").body["requester_id"].to_i
      ticket.user.update_attribute(:zendesk_id, zendesk_requester_id)
      Ticket.delay(priority: 25).verify_user(ticket.user.id)
    end

    ticket_id
  end

  def self.verify_user(user_id)
    if user = User.find_by_id(user_id)
      Zendesk.put("/users/#{user.zendesk_id}.xml", "<user><password>#{SecureRandom.hex(13)}</password><is-verified>true</is-verified></user>")
    end
  end

  def initialize(params = {})
    @params = params
  end

  def user
    @user ||= User.find_by_id(@params[:user_id]) || nil
  end

  def site
    @site ||= Site.find_by_token(@params[:site_token]) || nil
  end

  def subject
    @subject ||= @params[:subject].try(:to_s)
  end

  def message
    @message ||= message_with_site(@params[:message])
  end

  def save
    valid? && Ticket.delay(priority: 25).post_ticket(@params)
  end

  def to_key
    nil
  end

  def to_xml(options = {})
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.ticket do
      xml.tag!(:subject, subject)
      xml.tag!(:description, message)
      xml.tag!(:"set-tags", "#{user.support}-support") if user.email_support?
      if user.zendesk_id?
        xml.tag!(:"requester-id", user.zendesk_id)
      else
        xml.tag!(:"requester-name", user.name)
        xml.tag!(:"requester-email", user.email)
      end
    end
  end

  private

  def user_can_send_ticket
    if user && !user.email_support?
      self.errors.add(:base, "You can't send new tickets!")
    end
  end

  def message_with_site(message)
    full_message  = site ? "Request for site: (#{site.token}) #{site.hostname}\n\n" : ''
    full_message += message.to_s
  end

end
