# coding: utf-8
require_dependency 'active_model'
require_dependency 'users/support_manager'

class SupportRequest < Struct.new(:params)
  include ActiveModel::Validations

  attr_accessor :site_token, :subject, :message, :test_page, :env, :uploads

  validates :user, :subject, :message, presence: true

  def user
    @user ||= User.find_by_id(params[:user_id])
  end

  def site
    @site ||= Site.find_by_token(params[:site_token])
  end

  def subject
    @subject ||= params[:subject].to_s.strip
  end

  def message
    @message ||= params[:message].to_s.strip
  end

  def comment
    @comment ||= comment_with_additional_info(message)
  end

  def test_page
    @test_page ||= params[:test_page].to_s.strip
  end

  def env
    @env ||= params[:env].to_s.strip
  end

  def to_key
    nil
  end

  def to_params
    parameters = { subject: subject, comment: { value: comment }, uploads: params[:uploads], external_id: user.id }
    parameters[:tags] = ["#{Users::SupportManager.new(user).level}-support"]
    if user.zendesk_id?
      parameters[:requester_id] = user.zendesk_id
    else
      parameters[:requester] = { name: user.name || user.email, email: user.email }
    end

    parameters
  end

  private

  def comment_with_additional_info(message)
    full_message = ''
    full_message += "Request for site: (#{site.token}) #{site.hostname}\n" if site
    full_message += "The issue occurs on this page: #{test_page}\n" unless test_page.empty?
    full_message += "The issue occurs under this environment: #{env}\n" unless env.empty?
    full_message += "\n#{message.to_s}"
  end

end
