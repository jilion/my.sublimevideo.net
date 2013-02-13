FactoryGirl.define do

  # ===============
  # = User models =
  # ===============
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

    factory :user do
      cc_type        'visa'
      cc_last_digits '1111'
      cc_expire_on   { 1.year.from_now.end_of_month.to_date }
      cc_updated_at  { Time.now.utc }
    end
  end


  factory :admin do
    sequence(:email) { |n| "email#{n}@admin.com" }
    password         "123456"
  end

  factory :feedback do
    user
    reason 'support'
  end

  # ===============
  # = Site models =
  # ===============
  factory :site, class: Site do
    sequence(:hostname) { |n| "jilion#{n}.com" }
    user
  end


  factory :kit do
    site
  end


  # ==============
  # = Log models =
  # ==============
  factory :log_voxcast, class: Log::Voxcast do
    name "cdn.sublimevideo.net.log.1275002700-1275002760.gz"
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

  # ===============
  # = Mail models =
  # ===============
  factory :mail_template, class: MailTemplate do
    sequence(:title) { |n| "Pricing survey #{n}" }
    subject          "{{user.name}} ({{user.email}}), help us shaping the right pricing - The SublimeVideo Team"
    body             "Please respond to the survey, by clicking on the following url: http://survey.com"
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

  # ===============
  # = Plan models =
  # ===============
  factory :plan do
    sequence(:name)      { |n| "plus#{n}" }
    cycle                "month"
    video_views          10_000
    stats_retention_days 365
    price                1000
    support_level        1
  end

  # ================================
  # = Invoice & transaction models =
  # ================================
  factory :invoice do
    site
    invoice_items_amount 9999
    amount               9999
    vat_rate             0.08
    vat_amount           798

    factory :paid_invoice do
      state   'paid'
      paid_at { Time.now.utc }
    end

    factory :failed_invoice do
      state          'failed'
      last_failed_at { Time.now.utc }
    end

    factory :canceled_invoice do
      state 'canceled'
    end

    factory :waiting_invoice do
      state 'waiting'
    end
  end

  factory :invoice_item do
    started_at { Time.now.utc.beginning_of_month }
    ended_at   { Time.now.utc.end_of_month }
    price      { item.price }
    amount     { item.price }

    factory :plan_invoice_item, class: InvoiceItem::Plan do
      item { FactoryGirl.create(:plan) }
    end

    factory :addon_plan_invoice_item, class: InvoiceItem::AddonPlan do
      item { FactoryGirl.create(:addon_plan) }
    end

    factory :app_design_invoice_item, class: InvoiceItem::AppDesign do
      item { FactoryGirl.create(:app_design) }
    end
  end

  factory :transaction do
    factory :paid_transaction do
      state 'paid'
    end

    factory :failed_transaction do
      state 'failed'
      error 'Credit card refused'
    end
  end

  # ===============
  # = Deal models =
  # ===============
  factory :deal do
    sequence(:token)   { |n| "rts#{n}" }
    name               "Real-Time Stats promotion #1"
    kind               'yearly_plans_discount'
    availability_scope 'active'
    started_at         { 2.weeks.ago }
    ended_at           { 2.weeks.from_now }
  end

  factory :deal_activation do
    deal
    user
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

  # ===================
  # = My stats models =
  # ===================
  factory :site_second_stat, class: Stat::Site::Second do
  end
  factory :site_minute_stat, class: Stat::Site::Minute do
  end
  factory :site_hour_stat, class: Stat::Site::Hour do
  end
  factory :site_day_stat, class: Stat::Site::Day do
  end
  factory :video_second_stat, class: Stat::Video::Second do
  end
  factory :video_minute_stat, class: Stat::Video::Minute do
  end
  factory :video_hour_stat, class: Stat::Video::Hour do
  end
  factory :video_day_stat, class: Stat::Video::Day do
  end

  factory :video_tag do
    site
    site_token      { site.token }
    sequence(:uid)  { |n| "video_uid_#{n}" }
    uid_origin      'attribute'
    sequence(:name) { |n| "Video Tag #{n}" }
    name_origin     'attribute'
    poster_url      'http://media.sublimevideo.net/vpa/ms_800.jpg'
    size            '640x360'
    duration        '10000'

    current_sources %w[57fb2708 27fe0de1 2625adcf ff83f239]
    sources         { {
      '57fb2708' => {
        url: 'http://media.sublimevideo.net/vpa/ms_360p.mp4',
        quality: 'base',
        family: 'mp4',
        resolution: '640x360'
      },
      '27fe0de1' => {
        url: 'http://media.sublimevideo.net/vpa/ms_720p.mp4',
        quality: 'hd',
        family: 'mp4',
        resolution: '1280x720'
      },
      '2625adcf' => {
        url: 'http://media.sublimevideo.net/vpa/ms_360p.webm',
        quality: 'base',
        family: 'webm',
        resolution: '640x360'
      },
      'ff83f239' => {
        url: 'http://media.sublimevideo.net/vpa/ms_720p.webm',
        quality: 'hd',
        family: 'webm',
        resolution: '1280x720'
      }
    } }
    settings       { { 'badged' => true } }
  end

  factory :stats_export do
    st   { FactoryGirl.create(:site).token }
    from { 30.days.ago.midnight.to_i }
    to   { 1.days.ago.midnight.to_i }
    file { File.new(Rails.root.join('spec/fixtures/release.zip')) }
  end

  # ================
  # = Stats models =
  # ================
  factory :users_stat, class: Stats::UsersStat do
  end

  factory :sites_stat, class: Stats::SitesStat do
  end

  factory :tweets_stat, class: Stats::TweetsStat do
  end

  # ==============
  # = API models =
  # ==============
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

  factory :tailor_made_player_request do
    name        "John Doe"
    email       "john@doe.com"
    topic       'agency'
    description "Want a player."
  end

end
