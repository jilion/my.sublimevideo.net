# http://github.com/thoughtbot/factory_girl

Factory.define :user do |f|
  f.full_name        "Joe Blow"
  f.sequence(:email) { |n| "email#{n}@user.com" }
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
  f.width   480
  f.height  640
  f.command 'Handbrake CLI blabla...'
end

Factory.define :video do |f|
  f.association    :user
  f.panda_video_id 'f72e511820c12dabc1d15817745225bd'
end

Factory.define :video_encoding do |f|
  f.association       :video
  f.association       :profile_version, :factory => :video_profile_version
end

Factory.define :log_voxcast, :class => Log::Voxcast do |f|
  f.name "cdn.sublimevideo.net.log.1275002700-1275002760.gz"
end

Factory.define :log_cloudfront_download, :class => Log::CloudfrontDownload do |f|
  f.name "E3KTK13341WJO.2010-06-16-08.2Knk9kOC.gz"
end

Factory.define :site_usage do |f|
  f.association :site
  f.association :log, :factory => :log_voxcast
end

Factory.define :invoice do |f|
  f.association :user
end

