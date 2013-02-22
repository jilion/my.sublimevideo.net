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
    VideoTag.all.find_each(batch_size: 100) do |video_tag|
      VideoTagMigrator.new(video_tag).migrate
      count += 1
      puts "#{count} video tags migrated." if count%1000 == 0
    end
    puts "DOOOOONE!"
  end
end