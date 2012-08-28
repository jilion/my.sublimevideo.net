# coding: utf-8
require_dependency 'ticket_manager'

class SupportRequest
  include ActiveModel::Validations

  attr_accessor :site_token, :subject, :message, :test_page, :env, :uploads

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

  def uploads=(paths)
    @params[:uploads] = []
    return unless paths.respond_to?(:each)

    paths.each do |path|
      filename = Rails.root.join('tmp', "#{Time.now.to_i}-#{path.original_filename}")
      file = File.open(filename, 'wb') { |f| f.write(path.read) }
      @params[:uploads] << filename
    end
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
    @message ||= @params[:message].try(:to_s)
  end

  def comment
    @comment ||= comment_with_additional_info(message)
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
      params[:requester] = { name: user.name, email: user.email }
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
    full_message += "The issue occurs on this page: #{@params[:test_page]}\n" if @params[:test_page]
    full_message += "The issue occurs under this environment: #{@params[:env]}\n" if @params[:env]
    full_message += "\n#{message.to_s}"
  end

end
