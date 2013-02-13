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
end
