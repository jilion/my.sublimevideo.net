require_dependency 'pusher_wrapper'

class VideoTagUpdater

  def self.update_video_tags(video_tags_meta_data)
    video_tags_meta_data.each do |(st, u), attrs|
      begin
        if video_tag = VideoTag.find_by_st_and_u(st, u)
          push_needed = video_tag.update_meta_data(attrs)
        else
          begin
            VideoTag.create(attrs.merge(st: st, u: u))
            push_needed = true
          rescue BSON::InvalidKeyName => ex
            Notify.send("BSON::InvalidKeyName with attrs: #{attrs}", exception: ex)
          end
        end
        if push_needed
          PusherWrapper.trigger("private-#{st}", 'video_tag', u: u, meta_data: attrs)
        end
      rescue BSON::InvalidStringEncoding
      end
    end
  end

end