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
  f.cc_type              "visa"
  f.cc_last_digits       1234
end

Factory.define :admin do |f|
  f.sequence(:email) { |n| "email#{n}@admin.com" }
  f.password         "123456"
end

Factory.define :site do |f|
  f.sequence(:hostname) { |n| "jilion#{n}.com" }
  f.dev_hostnames       '127.0.0.1, localhost'
  f.association         :user
  f.association         :plan
end

Factory.define :active_site, :parent => :site do |f|
  f.after_create { |site| site.activate }
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
  f.site_id { Factory(:site).id }
end

Factory.define :release do |f|
  f.zip { File.new(Rails.root.join('spec/fixtures/release.zip')) }
end

Factory.define :referrer do |f|
  f.url   "http://bob.com"
  f.token { Factory(:site).token }
  f.hits  12
end

Factory.define :mail_template, :class => MailTemplate do |f|
  f.sequence(:title) { |n| "Pricing survey #{n}" }
  f.subject          "{{user.full_name}} ({{user.email}}), help us shaping the right pricing"
  f.body             "Hi {{user.full_name}} ({{user.email}}), please respond to the survey, by clicking on the following url: http://survey.com"
end

Factory.define :mail_log, :class => MailLog do |f|
  f.association :template, :factory => :mail_template
  f.association :admin
  f.criteria    ["with_invalid_site"]
  f.user_ids    [1,2,3,4,5]
  f.snapshot    Hash.new.tap { |h|
                  h[:title]   = "Blabla"
                  h[:subject] = "Blibli"
                  h[:body]    = "Blublu"
                }
end

Factory.define :plan do |f|
  f.sequence(:name) { |n| "small#{n}" }
  f.cycle         "month"
  f.player_hits   10_000
  f.price         1000
end

Factory.define :addon do |f|
  f.sequence(:name) { |n| "SSL_#{n}" }
  f.price           33
end

Factory.define :invoice do |f|
  f.association :user
  f.started_at           { Time.now.utc.beginning_of_month }
  f.ended_at             { Time.now.utc.end_of_month }
  f.invoice_items_amount 10000
  f.amount               10000
  f.vat_rate             0.08
  f.vat_amount           800
end

Factory.define :invoice_item do |f|
  f.association :site, :factory => :active_site
  f.association :invoice
  f.started_at  { Time.now.utc.beginning_of_month }
  f.ended_at    { Time.now.utc.end_of_month }
end

Factory.define :plan_invoice_item, :parent => :invoice_item, :class => InvoiceItem::Plan do |f|
  f.item   { Factory(:plan) }
  f.price  1000
  f.amount 1000
end

Factory.define :addon_invoice_item, :parent => :invoice_item, :class => InvoiceItem::Addon do |f|
  f.item   { Factory(:addon) }
  f.price  10
  f.amount 10
end

Factory.define :lifetime do |f|
  f.association :site, :factory => :active_site
  f.item        { Factory(:addon) }
end

Factory.define :users_stat do |f|
  f.states_count  { {} }
end

Factory.define :sites_stat do |f|
  f.states_count  { {} }
  f.plans_count   { {} }
  f.addons_count  { {} }
end
