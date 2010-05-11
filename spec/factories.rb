# http://github.com/thoughtbot/factory_girl

Factory.define :user do |f|
  f.full_name               "Joe Blow"
  f.sequence(:email)        { |n| "email#{n}@user.com" }
  f.password                "123456"
end

Factory.define :site do |f|
  f.hostname        "youtube.com"
  f.dev_hostnames   "localhost, 127.0.0.1"
  f.association :user, :factory => :user
end
