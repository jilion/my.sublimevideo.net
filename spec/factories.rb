# http://github.com/thoughtbot/factory_girl

Factory.define :user do |f|
  f.first_name           "John"
  f.last_name            "Doe"
  f.country              "CH"
  f.postal_code          "2000"
  f.use_personal         true
  f.sequence(:email)     { |n| "email#{n}@user.com" }
  f.password             "123456"
  f.terms_and_conditions "1"
end

Factory.define :admin do |f|
  f.sequence(:email) { |n| "email#{n}@admin.com" }
  f.password         "123456"
end

Factory.define :site do |f|
  f.sequence(:hostname) { |n| "jilion#{n}.com" }
  f.association         :user
end

Factory.define :log_voxcast, :class => Log::Voxcast do |f|
  f.name "cdn.sublimevideo.net.log.1275002700-1275002760.gz"
end

Factory.define :log_s3_player, :class => Log::Amazon::S3::Player do |f|
  f.name "2010-07-16-05-22-13-8C4ECFE09170CCD5"
end

Factory.define :log_s3_loaders, :class => Log::Amazon::S3::Loaders do |f|
  f.name "2010-07-14-09-22-26-63B226D3944909C8"
end

Factory.define :log_s3_licenses, :class => Log::Amazon::S3::Licenses do |f|
  f.name "2010-07-14-11-29-03-BDECA2599C0ADB7D"
end

Factory.define :site_usage do |f|
  f.site_id     { Factory(:site).id }
  f.association :log, :factory => :log_voxcast
end

Factory.define :invoice do |f|
  f.association :user
end

Factory.define :release do |f|
  f.zip { File.new(Rails.root.join('spec/fixtures/release.zip')) }
end

Factory.define :referrer do |f|
  f.url   "http://bob.com"
  f.token { Factory(:site).token }
  f.hits  12
end

Factory.define :mail_template, :class => Mail::Template do |f|
  f.sequence(:title) { |n| "Pricing survey #{n}" }
  f.subject          "{{user.full_name}}, help us shaping the right pricing"
  f.body             "Hi {{user.full_name}}, please respond to the survey, by clicking on the following link:\nhttp://survey.com"
end

Factory.define :mail_log, :class => Mail::Log do |f|
  f.association :template, :factory => :mail_template
  f.association :admin
  f.criteria    ["with_activity"]
  f.user_ids    [1,2,3,4,5]
  f.snapshot    Hash.new.tap { |h|
                  h[:title]   = "Blabla"
                  h[:subject] = "Blibli"
                  h[:body]    = "Blublu"
                }
end