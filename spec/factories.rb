FactoryGirl.define do
  factory :user_no_cc, :class => User do
    first_name           "John"
    last_name            "Doe"
    country              "CH"
    postal_code          "2000"
    use_personal         true
    sequence(:email)     { |n| "email#{n}@user.com" }
    password             "123456"
    terms_and_conditions "1"
  end

  factory :user_real_cc, :parent => :user_no_cc do
    cc_brand              'visa'
    cc_full_name          'John Doe Huber'
    cc_number             '4111111111111111'
    cc_expiration_month   { 1.year.from_now.month }
    cc_expiration_year    { 1.year.from_now.year }
    cc_verification_value '111'
    after_create          { |user| user.apply_pending_credit_card_info }
  end

  factory :user, :parent => :user_no_cc do
    cc_type        'visa'
    cc_last_digits '1111'
    cc_expire_on   { 1.year.from_now.end_of_month.to_date }
    cc_updated_at  { Time.now.utc }
  end

  factory :admin do
    sequence(:email) { |n| "email#{n}@admin.com" }
    password         "123456"
  end

  factory :new_site, :class => Site do
    sequence(:hostname) { |n| "jilion#{n}.com" }
    dev_hostnames       '127.0.0.1, localhost'
    plan_id             { Factory.create(:plan).id }
    user
  end

  # Site in trial
  factory :site, :parent => :new_site do
    after_build do |site|
      site.pend_plan_changes
      site.apply_pending_plan_changes
      # site.send(:puts, site.errors.inspect) unless site.valid?
    end
  end

  # Site in trial
  factory :site_not_in_trial, :parent => :site do
    trial_started_at { BusinessModel.days_for_trial.days.ago }
  end

  # Site not anymore in trial
  factory :site_with_invoice, :parent => :new_site do
    trial_started_at { BusinessModel.days_for_trial.days.ago }
    first_paid_plan_started_at { Time.now.utc }
    after_build  { |site| VCR.insert_cassette('ogone/visa_payment_generic') }
    after_create do |site|
      # this is needed since "instant charging" is now only done on upgrade (not on post-trial activation)
      Transaction.charge_invoices_by_user_id(site.user.id)
      VCR.eject_cassette
      site.apply_pending_plan_changes
      site.reload
    end
  end

  factory :site_pending, :parent => :new_site do
    after_build  { |site| VCR.insert_cassette('ogone/visa_payment_generic') }
    after_create { |site| VCR.eject_cassette }
  end

  factory :log_voxcast, :class => Log::Voxcast do
    name "cdn.sublimevideo.net.log.1275002700-1275002760.gz"
  end

  factory :log_s3_player, :class => Log::Amazon::S3::Player do
    name "2010-07-16-05-22-13-8C4ECFE09170CCD5"
  end

  factory :log_s3_loaders, :class => Log::Amazon::S3::Loaders do
    name "2010-07-14-09-22-26-63B226D3944909C8"
  end

  factory :log_s3_licenses, :class => Log::Amazon::S3::Licenses do
    name "2010-07-14-11-29-03-BDECA2599C0ADB7D"
  end

  factory :site_usage do
    site_id { Factory.create(:site).id }
  end

  factory :release do
    zip { File.new(Rails.root.join('spec/fixtures/release.zip')) }
  end

  factory :referrer do
    url   "http://bob.com"
    token { Factory.create(:site).token }
    hits  12
  end

  factory :mail_template, :class => MailTemplate do
    sequence(:title) { |n| "Pricing survey #{n}" }
    subject          "{{user.full_name}} ({{user.email}}), help us shaping the right pricing - The SublimeVideo Team"
    body             "Hi {{user.full_name}} ({{user.email}}), please respond to the survey, by clicking on the following url: http://survey.com - The SublimeVideo Team"
  end

  factory :mail_log, :class => MailLog do
    template :factory => :mail_template
    admin
    criteria    ["all"]
    user_ids    [1,2,3,4,5]
    snapshot    Hash.new.tap { |h|
                  h[:title]   = "Blabla"
                  h[:subject] = "Blibli"
                  h[:body]    = "Blublu"
                }
  end

  factory :plan do
    sequence(:name)      { |n| "silver#{n}" }
    cycle                "month"
    video_views          10_000
    stats_retention_days 365
    price                1000
    support_level        0
  end

  factory :free_plan, :class => Plan  do
    name                 "free"
    cycle                "none"
    video_views          0
    stats_retention_days 0
    price                0
    support_level        0
  end

  factory :sponsored_plan, :class => Plan  do
    name                 "sponsored"
    cycle                "none"
    video_views          0
    stats_retention_days nil
    price                0
    support_level        1
  end

  factory :custom_plan, :class => Plan do
    sequence(:name)      { |n| "custom#{n}" }
    cycle                "month"
    video_views          10_000_000
    stats_retention_days nil
    price                20_000
    support_level        1
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
    started_at  { Time.now.utc.beginning_of_month }
    ended_at    { Time.now.utc.end_of_month }
  end

  factory :plan_invoice_item, parent: :invoice_item, class: InvoiceItem::Plan do
    item   { Factory.create(:plan) }
    price  1000
    amount 1000
  end

  factory :transaction do
  end

  factory :users_stat do
    states_count  { {} }
  end

  factory :sites_stat do
    states_count  { {} }
    plans_count   { {} }
  end

  factory :site_stat, class: Stat::Site do
  end

  factory :video_stat, class: Stat::Video do
  end

  factory :video_tag do

  end

  factory :tweet do
    sequence(:tweet_id) { |n| n }
    keywords            %w[sublimevideo jilion]
    from_user_id        1
    from_user           'toto'
    to_user_id          2
    to_user             'tata'
    iso_language_code   'en'
    profile_image_url   'http://yourimage.com/img.jpg'
    content             "This is my first tweet!"
    tweeted_at          { Time.now.utc }
    favorited           false
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
