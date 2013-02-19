class VideoTagsPopulator < Populator

  def execute(site)
    VideoTag.where(site_id: site.id).delete_all

    (5 + rand(25)).times do |i|
      case i % 3
      when 0
        VideoTagUpdater.update(site.token, "video#{i}", {
          uo: "s",
          n: "Video #{i} long name test truncate",
          no: "s",
          cs: ["83cb4c27","83cb4c57","af355ec8", "af355ec9"],
          p: "http#{'s' if i.even?}://d1p69vb2iuddhr.cloudfront.net/assets/www/demo/midnight_sun_800-4f8c545242632c5352bc9da1addabcf5.jpg",
          z: "544x306",
          s: {
            "83cb4c27" => { u: "http://media.sublimevideo.net/v/midnight_sun_sv1_360p.mp4", q: "base", f: "mp4" }.stringify_keys,
            "83cb4c57" => { u: "http://media.sublimevideo.net/v/midnight_sun_sv1_720p.mp4", q: "hd", f: "mp4" }.stringify_keys,
            "af355ec8" => { u: "http://media.sublimevideo.net/v/midnight_sun_sv1_360p.webm", q: "base", f: "webm" }.stringify_keys,
            "af355ec9" => { u: "http://media.sublimevideo.net/v/midnight_sun_sv1_720p.webm", q: "hd", f: "webm" }.stringify_keys,
          }
        }.stringify_keys)
      when 1
        VideoTagUpdater.update(site.token, "video#{i}", {
          uo: "s",
          n: "Private Vimeo Pro",
          no: "a",
          cs: ["83cb4c27","83cb4c57"],
          p: "https://secure-b.vimeocdn.com/ts/358/030/358030879_960.jpg",
          z: "544x306",
          s: {
            "83cb4c27" => { u: "http://player.vimeo.com/external/51920681.sd.mp4?s=117259e431f97030b1150ddb5ce5858a", q: "base", f: "mp4" }.stringify_keys,
            "83cb4c57" => { u: "http://player.vimeo.com/external/51920681.hd.mp4?s=70273279a571e027c54032e70db61253", q: "hd", f: "mp4" }.stringify_keys,
          }
        }.stringify_keys)
      when 2
        VideoTagUpdater.update(site.token, "video#{i}", {
          uo: "s",
          i: 'rAq2rNEru8A',
          io: 'y'
        }.stringify_keys)
      end
    end
    puts "#{site.video_tags.size} video tags created for #{site.hostname}"
  end

end
