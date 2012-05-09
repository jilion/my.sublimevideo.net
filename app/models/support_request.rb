# coding: utf-8
class SupportRequest
  include ActiveModel::Validations

  attr_accessor :site_token, :subject, :message

  validates :user, :subject, :message, presence: true

  validate :user_can_send_ticket

  # This method simply instantiate a new SupportRequest object from the given params
  # and post it to the ticketing service
  def self.post(params)
    support_request = SupportRequest.new(params)
    TicketManager.create(support_request)

    support_request
  end

  # Takes params
  def initialize(params = {})
    @params = params
  end

  def delay_post
    valid? && SupportRequest.delay(priority: 25).post(@params)
  end

  def user
    @user ||= User.find_by_id(@params[:user_id])
  end

  def site
    @site ||= Site.find_by_token(@params[:site_token])
  end

  def subject
    @subject ||= @params[:subject].try(:to_s)
  end

  def message
    @message ||= message_with_site(@params[:message])
  end

  def to_key
    nil
  end

  def to_params
    params = { subject: subject, description: message }
    params[:set_tags] = ["#{user.support}-support"] if user.email_support?
    if user.zendesk_id?
      params[:requester_id] = user.zendesk_id
    else
      params[:requester_name]  = user.name
      params[:requester_email] = user.email
    end

    params
  end

  private

  def user_can_send_ticket
    if user && !user.email_support?
      self.errors.add(:base, "You don't have access to email support, please upgrade one of your sites's plan.")
    end
  end

  def message_with_site(message)
    full_message  = site ? "Request for site: (#{site.token}) #{site.hostname}\n\n" : ''
    full_message += message.to_s
  end

end
