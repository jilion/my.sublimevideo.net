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
  f.name    'iphone_720p'
  f.extname '.mp4'
end

Factory.define :video_profile_version do |f|
  f.association      :profile, :factory => :video_profile
  f.panda_profile_id '5e08a5612e8982ef2f7482e0782bbe02'
end

Factory.define :video do |f|
  f.association    :user
  f.panda_video_id 'f72e511820c12dabc1d15817745225bd'
end

Factory.define :video_encoding do |f|
  f.file              File.open("#{Rails.root}/spec/fixtures/railscast_intro.mov")
  f.panda_encoding_id 'd05be7d3f3fa16ff83a584e02ddb1aaf'
end

Factory.define :log do |f|
  f.name "cdn.sublimevideo.net.log.1275002700-1275002760.gz"
end

Factory.define :site_usage do |f|
  f.association :site
  f.association :log
end

Factory.define :invoice do |f|
  f.association :user
end

