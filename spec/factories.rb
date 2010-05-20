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

Factory.define :video do |f|
  f.file File.open("#{Rails.root}/spec/fixtures/railscast_intro.mov")
end

# FYI, can't use type (the Ruby's one is used instead of the factory_girl's method_missing's one)
# See: http://github.com/thoughtbot/factory_girl/issues#issue/4
Factory.define :video_original, :class => VideoOriginal, :parent => :video do |f|
  f.association :user
end

Factory.define :video_format, :class => VideoFormat, :parent => :video do |f|
  f.association :original, :factory => :video_original
  f.name        'iPhone'
end

Factory.define :log do |f|
  f.name        "cdn.sublimevideo.net.log.1274269140-1274269200.gz"
end
