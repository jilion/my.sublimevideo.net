# coding: utf-8
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
    valid? && delay(priority: 25).post_ticket
  end

  def post_ticket
    response = Zendesk.post("/tickets.xml", self.to_xml)
    ticket_id = response['location'].match(%r(#{Zendesk.base_url}/tickets/(\d+)\.xml))[1].to_i
    raise "Can't find ticket at: #{response['location']}!" if ticket_id.blank?

    if !@user.zendesk_id? && zendesk_requester_id = JSON[Zendesk.get("/tickets/#{ticket_id}.json").body]["requester_id"].to_i
      @user.update_attribute(:zendesk_id, zendesk_requester_id)
      Ticket.delay(:priority => 25).verify_user(@user.id)
    end

    ticket_id
  end

  def self.verify_user(user_id)
    if user = User.find(user_id)
      Zendesk.put("/users/#{user.zendesk_id}.xml", "<user><password>#{SecureRandom.hex(13)}</password><is-verified>true</is-verified></user>")
    end
  end

  def to_key
    nil
  end

  def to_xml(options={})
    xml = Builder::XmlMarkup.new(indent: 2)
    xml.ticket do
      xml.tag!(:subject, @subject)
      xml.tag!(:description, @message)
      xml.tag!(:"set-tags", "#{@type} #{@user.support}-support")
      if @user.zendesk_id?
        xml.tag!(:"requester-id", @user.zendesk_id)
      else
        xml.tag!(:"requester-name", h(@user.full_name))
        xml.tag!(:"requester-email", h(@user.email))
      end
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

