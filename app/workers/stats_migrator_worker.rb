require 'sidekiq'

class StatsMigratorWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'stats-migration'

  def perform(stat_class, data)
    # method handled in stsv
  end
end
