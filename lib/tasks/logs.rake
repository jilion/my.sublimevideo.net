namespace :logs do
  
  desc "Clear all CDN logs & SiteUsage"
  task :reset => :environment do
    puts "Stop all logs delayed_job"
    Delayed::Job.where(:handler =~ '%download_and_save_new_logs%').delete_all
    Delayed::Job.where(:handler =~ '%process%').delete_all
    puts "Destroy all Logs"
    Log.destroy_all
    puts "Delete all SiteUsages"
    SiteUsage.destroy_all
    puts "Clean all site hits caches"
    Site.update_all(
      :loader_hits_cache => 0,
      :js_hits_cache      => 0,
      :flash_hits_cache   => 0
    )
    puts "Relaunch logs download & parsing delayed_job"
    Log.delay_new_logs_download
  end

end
