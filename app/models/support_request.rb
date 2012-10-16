# coding: utf-8
require_dependency 'ticket_manager'

class SupportRequest
  include ActiveModel::Validations

  attr_accessor :site_token, :subject, :message, :test_page, :env, :uploads

  validates :user, :subject, :message, presence: true

  validate :user_can_send_ticket

  # Takes params
  def initialize(params = {})
    @params = params
  end

  def post
    valid? && TicketManager.create(self)
  end

  def user
    @user ||= User.find_by_id(@params[:user_id])
  end

  def site
    @site ||= Site.find_by_token(@params[:site_token])
  end

  def subject
    @subject ||= @params[:subject].to_s.strip
  end

  def message
    @message ||= @params[:message].to_s.strip
  end

  def comment
    @comment ||= comment_with_additional_info(message)
  end

  def test_page
    @test_page ||= @params[:test_page].to_s.strip
  end

  def env
    @env ||= @params[:env].to_s.strip
  end

  def to_key
    nil
  end

  def to_params
    params = { subject: subject, comment: { value: comment }, uploads: @params[:uploads], external_id: user.id }
    params[:tags] = ["#{user.support}-support"] if user.email_support?
    if user.zendesk_id?
      params[:requester_id] = user.zendesk_id
    else
      params[:requester] = { name: user.name_or_email, email: user.email }
    end

    params
  end

  private

  def user_can_send_ticket
    if user && !user.email_support?
      self.errors.add(:base, "You don't have access to email support, please upgrade one of your sites's plan.")
    end
  end

  def comment_with_additional_info(message)
    full_message = ''
    full_message += "Request for site: (#{site.token}) #{site.hostname} (in #{site.plan.title} plan)\n" if site
    full_message += "The issue occurs on this page: #{test_page}\n" unless test_page.empty?
    full_message += "The issue occurs under this environment: #{env}\n" unless env.empty?
    full_message += "\n#{message.to_s}"
  end

end
