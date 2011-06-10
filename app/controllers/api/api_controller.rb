class Api::ApiController < ActionController::Metal
  include AbstractController::Callbacks
  include ActionController::Helpers
  include ActionController::MimeResponds
  include ActionController::Rendering
  include ActionController::Renderers::All
  include ActionController::Instrumentation
  include Devise::Controllers::Helpers
  include ActsAsApi::Rendering

  ActsAsApi::RailsRenderer.setup

  respond_to :json, :xml

  before_filter :choose_version

  before_filter do |controller|
    unless wrong_signature?
      render(@content_type.to_sym => @error_message.send("to_#{@content_type}")) and return
    end
  end

private

  def wrong_signature?
    public_key = request.query_parameters.delete('public_key')

    if @api_token = ApiToken.find_by_public_key(public_key)
      signature   = request.query_parameters.delete('signature')
      url_to_sign = request.url.sub(/[?&]signature=#{CGI::escape(signature)}/, '')
      # Rails.logger.debug "signature: #{signature}"
      # Rails.logger.debug "url_to_sign: #{url_to_sign}"
      # Rails.logger.debug "signed url: #{UrlSigner.signed_url(url_to_sign, @api_token.secret_key)}"
      # Rails.logger.debug "digested signature: #{UrlSigner.signature(url_to_sign, @api_token.secret_key)}"

      if signature == UrlSigner.signature(url_to_sign, @api_token.secret_key)
        true
      else
        @error_message = { status: 403, message: "Forbidden! Wrong signature (public key '#{public_key}')." }
        false
      end
    else
      @error_message = { status: 404, message: "Unknown public key '#{public_key}'" }
      false
    end
  end

  protected

  def current_api_user
    @api_token.user
  end

  def choose_version
    version_and_content_type = request.headers['Accept'].match(%r{^application/vnd\.jilion\.sublimevideo(-v(\d+))?\+(\w+)$})
    @version      = version_and_content_type.try(:[], 2) || 1
    @content_type = version_and_content_type.try(:[], 3) || 'json'
  end

  def api_template(template=:private)
    "v#{@version}_#{template}".to_sym
  end

end
