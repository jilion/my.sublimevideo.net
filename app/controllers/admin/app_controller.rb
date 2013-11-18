class Admin::AppController < Admin::AdminController
  skip_before_filter :authenticate_admin!
  before_filter :_authenticate

  private

  def _authenticate
    authenticate_with_http_token do |token, options|
      token == ENV['PLAYER_ACCESS_TOKEN']
    end or authenticate_admin!
  end

  before_filter { |controller| require_role?('player') }
end
