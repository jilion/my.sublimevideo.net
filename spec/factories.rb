# http://github.com/thoughtbot/factory_girl

Factory.define :user do |f|
  f.full_name        "Joe Blow"
  f.sequence(:email) { |n| "email#{n}@user.com" }
  f.password         "123456"
  f.terms_and_conditions "1"
end

Factory.define :admin do |f|
  f.sequence(:email) { |n| "email#{n}@admin.com" }
  f.password         "123456"
end

Factory.define :site do |f|
  f.hostname    "youtube.com"
  f.association :user
end

Factory.define :video_profile do |f|
  f.title   'iPhone 720p'
  f.extname '.mp4'
end

Factory.define :video_profile_version do |f|
  f.association :profile, :factory => :video_profile
  f.width       480
  f.height      640
  f.command     'Handbrake CLI blabla...'
end

Factory.define :video do |f|
  f.association       :user
  f.panda_video_id    'f72e511820c12dabc1d15817745225bd'
  f.original_filename 'railscast_intro.mov'
  f.video_codec       'h264'
  f.audio_codec       'aac'
  f.extname           '.mov'
  f.file_size         '123456'
  f.duration          '12345'
  f.width             '640'
  f.height            '480'
  f.fps               '30'
  f.title             'Railscast Intro'
end

Factory.define :video_encoding do |f|
  f.association         :video
  f.association         :profile_version, :factory => :video_profile_version
  f.extname             '.mp4'
  f.file_size           123456
  f.width               640
  f.height              480
  f.encoding_time       1
  f.started_encoding_at Time.now
  f.encoding_status     'success'
end

Factory.define :log_voxcast, :class => Log::Voxcast do |f|
  f.name "cdn.sublimevideo.net.log.1275002700-1275002760.gz"
end

Factory.define :log_cloudfront_download, :class => Log::Cloudfront::Download do |f|
  f.name "E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz"
end

Factory.define :log_cloudfront_streaming, :class => Log::Cloudfront::Streaming do |f|
  f.name "EK1147O537VJ1.2010-06-23-07.9D0khw8j.gz"
end

Factory.define :site_usage do |f|
  f.association :site
  f.association :log, :factory => :log_voxcast
end

Factory.define :video_usage do |f|
  f.association :video
  f.association :log, :factory => :log_cloudfront_download
end

Factory.define :invoice do |f|
  f.association :user
end