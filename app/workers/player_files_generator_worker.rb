require 'sidekiq'

class PlayerFilesGeneratorWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'player'

  # @param [Symbol] event defines the event that triggered the `perform`
  #   events can be:
  #   * `:settings_update` => the site has been saved or its kits settings have been saved
  #   * `:addons_update`   => the site's addons have been updated
  #   * `:cancellation`    => the site has been archived
  #
  def perform(site_token, event)
    # handled in plsv
  end
end
