require 'video_tags_tasks'

namespace :video_tags do
  desc "Update video_tags name"
  task update_names: :environment do
    timed { VideoTagsTasks.update_names }
  end

  desc "Set video_tags site_token"
  task set_site_token: :environment do
    timed do
      Site.joins(:video_tags).select("DISTINCT sites.id, sites.token").find_each do |site|
        VideoTag.where(site_id: site.id).update_all(site_token: site.token)
      end
    end
  end

  desc "Migrate video_tags attributes to visv"
  task migrate_to_visv: :environment do
    count = 0
    VideoTag.where("id > 420934").select(:id).find_each do |video_tag|
      VideoTagMigrator.delay(queue: 'video_tags_migration').migrate(video_tag.id)
      count += 1
      if count%1000 == 0
        puts "#{count} video tags migration delayed."
        sleep 60
      end
    end
    puts "DOOOOONE!"
  end
end
