namespace :logs do
  
  desc "Clear all VoxcastCDN logs & SiteUsage"
  task :reset => :environment do
    puts "Stop all logs delayed_job"
    Delayed::Job.where(:handler.matches => '%fetch_download_and_create_new_logs%').delete_all
    Delayed::Job.where(:handler.matches => '%process%').delete_all
    puts "Destroy all Logs"
    Log.destroy_all
    puts "Delete all SiteUsages"
    SiteUsage.destroy_all
    puts "Clean all site hits caches"
    Site.update_all(
      :loader_hits_cache => 0,
      :player_hits_cache      => 0,
      :flash_hits_cache   => 0
    )
    puts "Relaunch logs download & parsing delayed_job"
    Log.delay_fetch_and_create_new_logs
  end

end
