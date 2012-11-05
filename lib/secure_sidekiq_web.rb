require 'sidekiq/web'

class SecureSidekiqWeb < Sidekiq::Web

  before do
    redirect '/login' unless authenticated_admin?
  end

  def authenticated_admin?
    request.env["warden"].authenticate? && request.env['warden'].user.is_a?(Admin)
  end

end
