FactoryGirl.define do
  factory :enthusiast do
    sequence(:email) { |n| "email#{n}@enthusiast.com" }
    free_text        "Love you!"
  end

  factory :enthusiast_site do
    enthusiast
    hostname "youtube.com"
  end

  factory :user_no_cc, class: User do
    name                 "John Doe"
    billing_name         "Remy Coutable"
    billing_address_1    "Avenue de France 71"
    billing_address_2    "Batiment B"
    billing_postal_code  "1004"
    billing_city         "Lausanne"
    billing_region       "VD"
    billing_country      "CH"
    use_personal         true
    sequence(:email)     { |n| "email#{n}@user.com" }
    password             "123456"
    terms_and_conditions "1"
  end

  factory :user_real_cc, parent: :user_no_cc do
    cc_brand              'visa'
    cc_full_name          'John Doe Huber'
    cc_number             '4111111111111111'
    cc_expiration_month   { 1.year.from_now.month }
    cc_expiration_year    { 1.year.from_now.year }
    cc_verification_value '111'
    after_build  { |user| VCR.insert_cassette('ogone/void_authorization') }
    after_create do |user|
      VCR.eject_cassette
      user.reload
    end
  end

  factory :user, parent: :user_no_cc do
    cc_type        'visa'
    cc_last_digits '1111'
    cc_expire_on   { 1.year.from_now.end_of_month.to_date }
    cc_updated_at  { Time.now.utc }
  end

  factory :admin do
    sequence(:email) { |n| "email#{n}@admin.com" }
    password         "123456"
  end

  factory :new_site, class: Site do
    sequence(:hostname) { |n| "jilion#{n}.com" }
    dev_hostnames       '127.0.0.1, localhost'
    plan_id             { Factory.create(:plan).id }
    user
  end

  # Site in trial
  factory :site, parent: :new_site do
    after_build do |site|
      site.prepare_pending_attributes
      site.apply_pending_attributes
      # site.send(:puts, site.errors.inspect) unless site.valid?
    end
  end

  # Site in trial
  factory :site_not_in_trial, parent: :site do
    trial_started_at { BusinessModel.days_for_trial.days.ago }
  end

  # Site not anymore in trial
  factory :site_with_invoice, parent: :new_site do
    trial_started_at { BusinessModel.days_for_trial.days.ago }
    first_paid_plan_started_at { Time.now.utc }
    after_build  { |site| VCR.insert_cassette('ogone/visa_payment_generic') }
    after_create do |site|
      # this is needed since "instant charging" is now only done on upgrade (not on post-trial activation)
      Transaction.charge_invoices_by_user_id(site.user.id)
      VCR.eject_cassette
      site.reload
    end
  end

  factory :site_pending, parent: :new_site do
    after_build  { |site| VCR.insert_cassette('ogone/visa_payment_generic') }
    after_create { |site| VCR.eject_cassette }
  end

  factory :log_voxcast, class: Log::Voxcast do
    name "cdn.sublimevideo.net.log.1275002700-1275002760.gz"
  end

  factory :log_s3_player, class: Log::Amazon::S3::Player do
    name "2010-07-16-05-22-13-8C4ECFE09170CCD5"
  end

  factory :log_s3_loaders, class: Log::Amazon::S3::Loaders do
    name "2010-07-14-09-22-26-63B226D3944909C8"
  end

  factory :log_s3_licenses, class: Log::Amazon::S3::Licenses do
    name "2010-07-14-11-29-03-BDECA2599C0ADB7D"
  end

  factory :site_usage do
    site
  end

  factory :release do
    zip { File.new(Rails.root.join('spec/fixtures/release.zip')) }
  end

  factory :referrer do
    url   "http://bob.com"
    token { '123456' }
    hits  12
  end

  factory :mail_template, class: MailTemplate do
    sequence(:title) { |n| "Pricing survey #{n}" }
    subject          "{{user.name}} ({{user.email}}), help us shaping the right pricing - The SublimeVideo Team"
    body             "Hi {{user.name}} ({{user.email}}), please respond to the survey, by clicking on the following url: http://survey.com - The SublimeVideo Team"
  end

  factory :mail_log, class: MailLog do
    template factory: :mail_template
    admin
    criteria ["all"]
    user_ids [1,2,3,4,5]
    snapshot Hash.new.tap { |h|
              h[:title]   = "Blabla"
              h[:subject] = "Blibli"
              h[:body]    = "Blublu"
             }
  end

  factory :plan do
    sequence(:name)      { |n| "plus#{n}" }
    cycle                "month"
    video_views          10_000
    stats_retention_days 365
    price                1000
    support_level        1
  end

  factory :free_plan, class: Plan  do
    name                 "free"
    cycle                "none"
    video_views          0
    stats_retention_days 0
    price                0
    support_level        0
  end

  factory :sponsored_plan, class: Plan  do
    name                 "sponsored"
    cycle                "none"
    video_views          0
    stats_retention_days nil
    price                0
    support_level        2
  end

  factory :custom_plan, class: Plan do
    sequence(:name)      { |n| "custom#{n}" }
    cycle                "month"
    video_views          10_000_000
    stats_retention_days nil
    price                20_000
    support_level        2
  end

  factory :invoice do
    site
    invoice_items_amount 10000
    amount               10000
    vat_rate             0.08
    vat_amount           800
  end

  factory :invoice_item do
    invoice
    started_at { Time.now.utc.beginning_of_month }
    ended_at   { Time.now.utc.end_of_month }
  end

  factory :plan_invoice_item, parent: :invoice_item, class: InvoiceItem::Plan do
    item   { Factory.create(:plan) }
    price  1000
    amount 1000
  end

  factory :transaction do
  end

  factory :users_stat, class: Stats::UsersStat do
    d            Time.now.utc.midnight
    states_count { {} }
    fr           2
    pa           1
    su           1
    ar           1
  end

  factory :sites_stat, class: Stats::SitesStat do
    d            Time.now.utc.midnight
    states_count { {} }
    plans_count  { {} }
  end

  factory :tweets_stat, class: Stats::TweetsStat do
    d Time.now.utc.midnight
    k { {} }
  end

  factory :site_stat, class: Stat::Site do
    d Time.now.utc.midnight
    t { '123456' }
  end

  factory :video_stat, class: Stat::Video do
    d Time.now.utc.midnight
  end

  factory :video_tag do
  end

  factory :tweet do
    sequence(:tweet_id) { |n| n }
    keywords          %w[sublimevideo jilion]
    from_user_id      1
    from_user         'toto'
    to_user_id        2
    to_user           'tata'
    iso_language_code 'en'
    profile_image_url 'http://yourimage.com/img.jpg'
    content           "This is my first tweet!"
    tweeted_at        { Time.now.utc }
    favorited         false
  end

  factory :client_application do
    user
    name         "Agree2"
    url          "http://test.com"
    support_url  "http://test.com/support"
    callback_url "http://test.com/callback"
    key          "one_key"
    secret       "MyString"
  end

  factory :oauth_token do
    client_application
    user
    callback_url "http://test.com/callback"
  end

  factory :oauth2_token do
    client_application
    user
    callback_url "http://test.com/callback"
  end

  factory :oauth2_verifier do
    client_application
    user
    callback_url "http://test.com/callback"
  end
end
