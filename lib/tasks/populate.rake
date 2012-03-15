# coding: utf-8
require 'state_machine'
require 'ffaker' if Rails.env.development?

BASE_USERS = [["Mehdi Aminian", "mehdi@jilion.com"], ["Zeno Crivelli", "zeno@jilion.com"], ["Thibaud Guillaume-Gentil", "thibaud@jilion.com"], ["Octave Zangs", "octave@jilion.com"], ["Rémy Coutable", "remy@jilion.com"]]
COUNTRIES = %w[US FR CH ES DE BE GB CN SE NO FI BR CA]
BASE_SITES = %w[vimeo.com dribbble.com jilion.com swisslegacy.com maxvoltar.com 37signals.com youtube.com zeldman.com sumagency.com deaxon.com veerle.duoh.com]
# BASE_SITES = %w[sublimevideo.net jilion.com swisslegacy.com]

namespace :db do

  desc "Load all development fixtures."
  task populate: ['populate:empty_all_tables', 'populate:all']

  namespace :populate do
    desc "Empty all the tables"
    task empty_all_tables: :environment do
      timed { empty_tables("delayed_jobs", "invoices_transactions", InvoiceItem, Invoice, Transaction, Log, MailTemplate, MailLog, Site, SiteUsage, User, Admin, Plan) }
    end

    desc "Load all development fixtures."
    task all: :environment do
      disable_perform_deliveries do
        delete_all_files_in_public('uploads/releases')
        delete_all_files_in_public('uploads/s3')
        delete_all_files_in_public('uploads/tmp')
        delete_all_files_in_public('uploads/voxcast')
        timed { create_plans }
        timed { create_admins }
        timed { create_users(argv_user) }
        timed { create_sites }
        timed { create_site_usages }
        timed { create_site_stats }
        timed { create_deals }
        timed { create_mail_templates }
      end
    end

    desc "Load Admin development fixtures."
    task admins: :environment do
      disable_perform_deliveries do
        timed { empty_tables(Admin) }
        timed { create_admins }
      end
    end

    desc "Load Enthusiast development fixtures."
    task enthusiasts: :environment do
      disable_perform_deliveries do
        timed { empty_tables(EnthusiastSite, Enthusiast) }
        timed { create_enthusiasts(argv_user) }
      end
    end

    desc "Load User development fixtures."
    task users: :environment do
      disable_perform_deliveries do
        timed { empty_tables("invoices_transactions", InvoiceItem, Invoice, Transaction, Site, User) }
        timed { create_users(argv_user) }
        empty_tables("delayed_jobs")
      end
    end

    desc "Load Site development fixtures."
    task sites: :environment do
      disable_perform_deliveries do
        timed { empty_tables("invoices_transactions", InvoiceItem, Invoice, Transaction, Site) }
        timed { create_sites }
        empty_tables("delayed_jobs")
      end
    end

    desc "Load Site development fixtures."
    task invoices: :environment do
      disable_perform_deliveries do
        timed { empty_tables("invoices_transactions", InvoiceItem, Invoice, Transaction) }
        timed { create_invoices(argv_user) }
        empty_tables("delayed_jobs")
      end
    end

    desc "Load Deals development fixtures."
    task deals: :environment do
      disable_perform_deliveries do
        timed { empty_tables(DealActivation, Deal) }
        timed { create_deals }
      end
    end

    desc "Load Mail templates development fixtures."
    task mail_templates: :environment do
      disable_perform_deliveries do
        timed { empty_tables(MailTemplate) }
        timed { create_mail_templates }
      end
    end

    desc "Create fake usages"
    task site_usages: :environment do
      disable_perform_deliveries do
        timed { empty_tables(SiteUsage) }
        timed { create_site_usages }
      end
    end

    desc "Create fake site stats"
    task site_stats: :environment do
      disable_perform_deliveries do
        timed { empty_tables(Stat::Site) }
        timed { create_site_stats(argv_user) }
      end
    end

    desc "Create fake users & sites stats"
    task users_and_sites_stats: :environment do
      disable_perform_deliveries do
        timed { create_users_stats }
        timed { create_sites_stats }
      end
    end

    desc "Create fake site stats"
    task recurring_site_stats: :environment do
      disable_perform_deliveries do
        timed { empty_tables(Stat::Site) }
        timed { create_site_stats(argv_user) }
        timed { recurring_site_stats_update(argv_user) }
      end
    end

    desc "Create fake site & video stats"
    task stats: :environment do
      disable_perform_deliveries do
        timed { create_stats(argv('site')) }
      end
    end

    desc "Create recurring fake site & video stats"
    task recurring_stats: :environment do
      disable_perform_deliveries do
        timed { recurring_stats_update(argv('site')) }
      end
    end

    desc "Create fake plans"
    task plans: :environment do
      disable_perform_deliveries do
        timed { empty_tables(Plan) }
        timed { create_plans }
      end
    end

    desc "Import MongoDB production databases locally (not the other way around don't worry!)"
    task import_mongo_prod: :environment do
      mongo_db_pwd = argv('password')
      raise "Please provide a password to access the production database like this: rake db:populate:import_mongo_prod password=MONGOHQ_PASSWORD" if mongo_db_pwd.nil?

      %w[sales_stats site_stats_stats site_usages_stats sites_stats tweets_stats users_stats tweets].each do |collection|
        timed do
          puts "Exporting production '#{collection}' collection"
          `mongodump -h hurley.member0.mongohq.com:10006 -d sublimevideo_production -u heroku -p #{mongo_db_pwd} -o db/backups/ --collection #{collection}`
          puts "Importing '#{collection}' collection locally"
          `mongorestore -h localhost -d sublimevideo_dev --collection #{collection} --drop -v db/backups/sublimevideo_production/#{collection}.bson`
        end
      end
    end
  end

end

namespace :user do

  desc "Expire the credit card of the user with the given email (EMAIL=xx@xx.xx) at the end of the month (or the opposite if already expiring at the end of the month)"
  task cc_will_expire: :environment do
    timed do
      email = argv("email")
      return if email.nil?

      User.find_by_email(email).tap do |user|
        date = if user.cc_expire_on == TimeUtil.current_month.last.to_date
          puts "Update credit card for #{email}, make it expire in 2 years..."
          2.years.from_now
        else
          puts "Update credit card for #{email}, make it expire at the end of the month..."
          TimeUtil.current_month.last
        end
        user.update_attributes({
          cc_type: 'visa',
          cc_full_name: user.name,
          cc_number: "4111111111111111",
          cc_verification_value: "111",
          cc_expire_on: date
        })
      end
    end
  end

  desc "Suspend/unsuspend a user given an email (EMAIL=xx@xx.xx), you can pass the count of failed invoices on suspend with FAILED_INVOICES=N"
  task suspended: :environment do
    timed do
      email = argv("email")
      return if email.nil?

      User.find_by_email(email).tap do |user|
        if user.suspended?
          puts "Unsuspend #{email}..."
          # user.state = 'active'
          user.update_attribute(:state, 'active')
        else
          puts "Suspend #{email}..."
          # user.state = 'suspended'
          # user.save!(validate: false)
          user.update_attribute(:state, 'suspended')
        end
      end
    end
  end

end

namespace :sm do

  desc "Draw the States Diagrams for every model having State Machine"
  task draw: :environment do
    %x(rake state_machine:draw CLASS=Invoice,Log,Site,User TARGET=doc/state_diagrams FORMAT=png ORIENTATION=landscape)
  end

end

private

def empty_tables(*tables)
  print "Deleting the content of #{tables.join(', ')}.. => "
  tables.each do |table|
    if table.is_a?(Class)
      table.delete_all
    else
      Site.connection.delete("DELETE FROM #{table} WHERE 1=1")
    end
  end
  puts "#{tables.join(', ')} empty!"
end

def create_admins
  disable_perform_deliveries do
    puts "Creating admins..."
    BASE_USERS.each do |admin_info|
      Admin.create(full_name: admin_info[0], email: admin_info[1], password: "123456")
      puts "Admin #{admin_info[1]}:123456"
    end
  end
end

def create_enthusiasts(user_id = nil)
  disable_perform_deliveries do
    (user_id ? [user_id] : 0.upto(BASE_USERS.count - 1)).each do |i|
      enthusiast = Enthusiast.create(email: BASE_USERS[i][1], interested_in_beta: true)
      enthusiast.confirmed_at = Time.now
      enthusiast.save!
      print "Enthusiast #{BASE_USERS[0]} created!\n"
    end
  end
end

def create_users(user_id = nil)
  created_at_array = (Date.new(2011,1,1)..100.days.ago.to_date).to_a
  disable_perform_deliveries do
    (user_id ? [user_id] : 0.upto(BASE_USERS.count - 1)).each do |i|
      user = User.new(
        enthusiast_id: rand(1000000),
        email: BASE_USERS[i][1],
        password: "123456",
        name: BASE_USERS[i][0],
        postal_code: Faker::Address.zip_code,
        country: COUNTRIES.sample,
        billing_name: BASE_USERS[i][0],
        billing_address_1: Faker::Address.street_address,
        billing_address_2: Faker::Address.secondary_address,
        billing_postal_code: Faker::Address.zip_code,
        billing_city: Faker::Address.city,
        billing_region: Faker::Address.uk_county,
        billing_country: COUNTRIES.sample,
        use_personal: true,
        terms_and_conditions: "1",
        cc_brand: 'visa',
        cc_full_name: BASE_USERS[i][0],
        cc_number: "4111111111111111",
        cc_verification_value: "111",
        cc_expiration_month: 12,
        cc_expiration_year: 2.years.from_now.year
      )
      user.created_at   = created_at_array.sample
      user.confirmed_at = user.created_at
      user.save!
      puts "User #{BASE_USERS[i][1]}:123456"
    end

    use_personal = false
    use_company  = false
    use_clients  = false
    case rand
    when 0..0.4
      use_personal = true
    when 0.4..0.7
      use_company = true
    when 0.7..1
      use_clients = true
    end
  end
end

def create_sites
  delete_all_files_in_public('uploads/licenses')
  delete_all_files_in_public('uploads/loaders')
  create_users if User.all.empty?
  create_plans if Plan.all.empty?

  free_plan      = Plan.free_plan
  standard_plans = Plan.standard_plans.all
  custom_plans   = Plan.custom_plans.all

  subdomains = %w[www blog my git sv ji geek yin yang chi cho chu foo bar rem]
  created_at_array = (2.months.ago.to_date..Date.today).to_a

  require 'invoice_item/plan'

  User.all.each do |user|
    BASE_SITES.each do |hostname|
      plan_id = rand > 0.4 ? (rand > 0.8 ? custom_plans.sample.token : standard_plans.sample.id) : free_plan.id
      site = user.sites.build(
        plan_id: plan_id,
        hostname: hostname
      )
      Timecop.travel(created_at_array.sample) do
        site.save_skip_pwd
      end

      if rand > 0.3
        site.cdn_up_to_date = true
        site.save_skip_pwd
      end
      site.sponsor! if rand > 0.85
    end
  end

  Site.activate_or_downgrade_sites_leaving_trial
  Invoice.open.all.each { |invoice| invoice.succeed! }

  puts "#{BASE_SITES.size} beautiful sites created for each user!"
end

def create_invoices(user_id = nil)
  users = user_id ? [User.find(user_id)] : User.all
  plans = Plan.standard_plans.all
  users.each do |user|
    user.sites.active.each do |site|
      if site.in_paid_plan?
        site.first_paid_plan_started_at = 2.months.ago
        site.trial_started_at = 3.months.ago
        site.save(validate: false)
        (5 + rand(15)).times do |n|
          Timecop.travel(n.months.from_now) do
            site.prepare_pending_attributes
            invoice = ::Invoice.construct(site: site, renew: rand > 0.5)
            puts invoice.errors.inspect unless invoice.valid?
            invoice.save!
            puts "Invoice created: $#{invoice.amount / 100.0}"
          end
        end
      end
    end
  end
end

def create_site_usages
  end_date = Date.today
  player_hits_total = 0
  Site.active.each do |site|
    start_date = (site.plan_cycle_started_at? ? site.plan_month_cycle_started_at : (1.month - 1.day).ago.midnight).to_date
    plan_video_views = site.in_sponsored_plan? || site.in_free_plan? ? Plan.standard_plans.all.sample.video_views : site.plan.video_views
    p = (case rand(4)
    when 0
      plan_video_views/30.0 - (plan_video_views/30.0/4)
    when 1
      plan_video_views/30.0 - (plan_video_views/30.0/8)
    when 2
      plan_video_views/30.0 + (plan_video_views/30.0/4)
    when 3
      plan_video_views/30.0 + (plan_video_views/30.0/8)
    end).to_i

    (start_date..end_date).each do |day|
      Timecop.travel(day) do
        loader_hits                = p * rand(100)
        main_player_hits           = (p * rand).to_i
        main_player_hits_cached    = (p * rand).to_i
        extra_player_hits          = (p * rand).to_i
        extra_player_hits_cached   = (p * rand).to_i
        dev_player_hits            = rand(100)
        dev_player_hits_cached     = (dev_player_hits * rand).to_i
        invalid_player_hits        = rand(500)
        invalid_player_hits_cached = (invalid_player_hits * rand).to_i
        player_hits = main_player_hits + main_player_hits_cached + extra_player_hits + extra_player_hits_cached + dev_player_hits + dev_player_hits_cached + invalid_player_hits + invalid_player_hits_cached
        requests_s3 = player_hits - (main_player_hits_cached + extra_player_hits_cached + dev_player_hits_cached + invalid_player_hits_cached)

        site_usage = SiteUsage.new(
          day: day.to_time.utc.midnight,
          site_id: site.id,
          loader_hits: loader_hits,
          main_player_hits: main_player_hits,
          main_player_hits_cached: main_player_hits_cached,
          extra_player_hits: extra_player_hits,
          extra_player_hits_cached: extra_player_hits_cached,
          dev_player_hits: dev_player_hits,
          dev_player_hits_cached: dev_player_hits_cached,
          invalid_player_hits: invalid_player_hits,
          invalid_player_hits_cached: invalid_player_hits_cached,
          player_hits: player_hits,
          flash_hits: (player_hits * rand / 3).to_i,
          requests_s3: requests_s3,
          traffic_s3: requests_s3 * 150000, # 150 KB
          traffic_voxcast: player_hits * 150000
        )
        site_usage.save!
        player_hits_total += player_hits
      end
    end
  end
  puts "#{player_hits_total} video-page views total!"
end

def create_users_stats
  day = 2.years.ago.midnight
  hash = { fr: 0, pa: 0, su: 0, ar: 0 }

  while day <= Time.now.utc.midnight
    hash[:d]   = day
    hash[:fr] += rand(100)
    hash[:pa] += rand(25)
    hash[:su] += rand(2)
    hash[:ar] += rand(4)

    Stats::UsersStat.create(hash)

    day += 1.day
  end
  puts "Fake users stats generated"
end

def create_sites_stats
  day = 2.years.ago.midnight
  hash = { fr: 0, sp: 0, tr: { plus: { m: 0, y: 0 }, premium: { m: 0, y: 0 } }, pa: { plus: { m: 0, y: 0 }, premium: { m: 0, y: 0 } }, su: 0, ar: 0 }

  while day <= Time.now.utc.midnight
    hash[:d]   = day
    hash[:fr] += rand(50)
    hash[:sp] += rand(2)

    hash[:tr][:plus][:m]    += rand(10)
    hash[:tr][:plus][:y]    += rand(5)
    hash[:tr][:premium][:m] += rand(5)
    hash[:tr][:premium][:y] += rand(2)
    hash[:pa][:plus][:m]    += rand(7)
    hash[:pa][:plus][:y]    += rand(3)
    hash[:pa][:premium][:m] += rand(4)
    hash[:pa][:premium][:y] += rand(2)

    hash[:su] += rand(3)
    hash[:ar] += rand(6)

    Stats::SitesStat.create(hash)

    day += 1.day
  end
  puts "Fake sites stats generated"
end

def create_site_stats(user_id = nil)
  users = user_id ? [User.find(user_id)] : User.all
  users.each do |user|
    user.sites.each do |site|
      # Days
      95.times.each do |i|
        stats = random_site_stats_inc(24 * 60 * 60)
        Stat::Site::Day.collection.update(
          { t: site.token, d: i.days.ago.change(hour: 0, min: 0, sec: 0, usec: 0).to_time },
          { "$inc" => stats },
          upsert: true
        )

        SiteUsage.create(
          day: i.days.ago.to_time.utc.midnight,
          site_id: site.id,
          loader_hits: 0,
          main_player_hits: stats.slice('pv.m', 'pv.em').values.sum,
          main_player_hits_cached: 0,
          extra_player_hits: stats['pv.e'],
          extra_player_hits_cached: 0,
          dev_player_hits: stats['pv.d'],
          dev_player_hits_cached: 0,
          invalid_player_hits: stats['pv.i'],
          invalid_player_hits_cached: 0,
          player_hits: stats.slice('pv.m', 'pv.e', 'pv.em', 'pv.d', 'pv.i').values.sum,
          flash_hits: stats.slice('md.f.d', 'md.f.m', 'md.f.t').values.sum,
          requests_s3: 0,
          traffic_s3: 0,
          traffic_voxcast: 0
        )
      end
      # Hours
      25.times.each do |i|
        Stat::Site::Hour.collection.update(
          { t: site.token, d: i.hours.ago.change(min: 0, sec: 0, usec: 0).to_time },
          { "$inc" => random_site_stats_inc(60 * 60) },
          upsert: true
        )
      end
      # Minutes
      60.times.each do |i|
        Stat::Site::Minute.collection.update(
          { t: site.token, d: i.minutes.ago.change(sec: 0, usec: 0).to_time },
          { "$inc" => random_site_stats_inc(60) },
          upsert: true
        )
      end
      # seconds
      60.times.each do |i|
        Stat::Site::Second.collection.update(
          { t: site.token, d: i.seconds.ago.change(usec: 0).to_time },
          { "$inc" => random_site_stats_inc(1) },
          upsert: true
        )
      end
      site.update_last_30_days_counters
    end
  end
  puts "Fake site(s) stats generated"
end

def create_stats(site_token = nil)
  sites = site_token ? [Site.find_by_token(site_token)] : Site.all
  sites.each do |site|
    VideoTag.where(st: site.token).delete_all
    Stat::Site::Day.where(t: site.token).delete_all
    Stat::Site::Hour.where(t: site.token).delete_all
    Stat::Site::Minute.where(t: site.token).delete_all
    Stat::Site::Second.where(t: site.token).delete_all
    Stat::Video::Day.where(st: site.token).delete_all
    Stat::Video::Hour.where(st: site.token).delete_all
    Stat::Video::Minute.where(st: site.token).delete_all
    Stat::Video::Second.where(st: site.token).delete_all
    videos_count = 20
    # Video Tags
    videos_count.times do |video_i|
      VideoTag.create(st: site.token, u: "video#{video_i}",
        uo: "s",
        n: "Video #{video_i} long name test truncate",
        no: "s",
        cs: ["83cb4c27","83cb4c57","af355ec8", "af355ec9"],
        p: "http#{'s' if video_i.even?}://d1p69vb2iuddhr.cloudfront.net/assets/www/demo/midnight_sun_800-4f8c545242632c5352bc9da1addabcf5.jpg",
        z: "544x306",
        s: {
          "83cb4c27" => { u: "http://media.jilion.com/videos/demo/midnight_sun_sv1_360p.mp4", q: "base", f: "mp4" },
          "83cb4c57" => { u: "http://media.jilion.com/videos/demo/midnight_sun_sv1_720p.mp4", q: "hd", f: "mp4" },
          "af355ec8" => { u: "http://media.jilion.com/videos/demo/midnight_sun_sv1_360p.webm", q: "base", f: "webm" },
          "af355ec9" => { u: "http://media.jilion.com/videos/demo/midnight_sun_sv1_720p.webm", q: "hd", f: "webm" },
        }
      )
    end

    # Days
    puts "Generating 95 days of stats for #{site.hostname}"
    95.times.each do |i|
      time = i.days.ago.change(hour: 0, min: 0, sec: 0, usec: 0).to_time
      Stat::Site::Day.collection.update(
        { t: site.token, d: time }, { "$inc" => random_site_stats_inc(24 * 60 * 60) }, upsert: true
      )
      videos_count.times do |video_i|
        Stat::Video::Day.collection.update(
          { st: site.token, u: "video#{video_i}", d: time }, { "$inc" => random_video_stats_inc(24 * 60 * 60) }, upsert: true
        )
      end
    end

    # Hours
    puts "Generating 25 hours of stats for #{site.hostname}"
    25.times.each do |i|
      time = i.hours.ago.change(min: 0, sec: 0, usec: 0).to_time
      Stat::Site::Hour.collection.update(
        { t: site.token, d: time }, { "$inc" => random_site_stats_inc(60 * 60) }, upsert: true
      )
      videos_count.times do |video_i|
        Stat::Video::Hour.collection.update(
          { st: site.token, u: "video#{video_i}", d: time }, { "$inc" => random_video_stats_inc(60 * 60) }, upsert: true
        )
      end
    end

    # Minutes
    puts "Generating 60 minutes of stats for #{site.hostname}"
    60.times.each do |i|
      time = i.minutes.ago.change(sec: 0, usec: 0).to_time
      Stat::Site::Minute.collection.update(
        { t: site.token, d: time }, { "$inc" => random_site_stats_inc(60) }, upsert: true
      )
      videos_count.times do |video_i|
        Stat::Video::Minute.collection.update(
          { st: site.token, u: "video#{video_i}", d: time }, { "$inc" => random_video_stats_inc(60) }, upsert: true
        )
      end
    end

    # Seconds
    puts "Generating 60 seconds of stats for #{site.hostname}"
    60.times.each do |i|
      time = i.seconds.ago.change(usec: 0).to_time
      Stat::Site::Second.collection.update(
        { t: site.token, d: time }, { "$inc" => random_site_stats_inc(1) }, upsert: true
      )
      videos_count.times do |video_i|
        Stat::Video::Second.collection.update(
          { st: site.token, u: "video#{video_i}", d: time }, { "$inc" => random_video_stats_inc(1) }, upsert: true
        )
      end
    end
    site.update_last_30_days_counters
  end
  puts "Fake site(s)/video(s) stats generated"
end

def recurring_site_stats_update(user_id)
  sites = User.find(user_id).sites
  puts "Begin recurring fake site(s) stats generation (each minute)"
  Thread.new do
    loop do
      second = Time.now.utc.change(usec: 0).to_time
      sites.each do |site|
        inc = random_site_stats_inc(1)
        Stat::Site::Second.collection.update({ t: site.token, d: second }, { "$inc" => inc }, upsert: true)
      end
      # puts "Site(s) stats seconds updated at #{second}"
      sleep 1
    end
  end
  Thread.new do
    loop do
      now = Time.now.utc
      if now.change(usec: 0) == now.change(sec: 0, usec: 0)
        sites.each do |site|
          inc = random_site_stats_inc(60)
          Stat::Site::Minute.collection.update({ t: site.token, d: (now - 1.minute).change(sec: 0, usec: 0).to_time },                  { "$inc" => inc }, upsert: true)
          Stat::Site::Hour.collection.update({ t: site.token, d: (now - 1.minute).change(min: 0, sec: 0, usec: 0).to_time },          { "$inc" => inc }, upsert: true)
          Stat::Site::Day.collection.update({ t: site.token, d: (now - 1.minute).change(hour: 0, min: 0, sec: 0, usec: 0).to_time }, { "$inc" => inc }, upsert: true)
        end

        json = {}
        json[:h] = true if now.change(sec: 0, usec: 0) == now.change(min: 0, sec: 0, usec: 0)
        json[:d] = true if now.change(min: 0, sec: 0, usec: 0) == now.change(hour: 0, min: 0, sec: 0, usec: 0)
        Pusher["stats"].trigger('tick', json)

        puts "Site(s) stats updated at #{now.change(sec: 0, usec: 0)}"
        sleep 50
      end
      sleep 0.9
    end
  end
  EM.run do
    EM.add_periodic_timer(1) do
      EM.defer do
        second = Time.now.change(usec: 0).to_time
        site = sites.order(:hostname).first()
        json = { "pv" => 1, "bp" => { "saf-osx" => 1 } }
        Pusher["private-#{site.token}"].trigger_async('stats', json.merge('id' => second.to_i))
        json = { "md" => { "f" => { "d" => 1 }, "h" => { "d" => 1 } } }
        Pusher["private-#{site.token}"].trigger_async('stats', json.merge('id' => second.to_i))
        json = { "vv" => 1 }
        Pusher["private-#{site.token}"].trigger_async('stats', json.merge('id' => second.to_i))
      end
    end
  end
end

def recurring_stats_update(site_token)
  site         = Site.find_by_token(site_token)
  last_second  = 0
  videos_count = 20
  EM.run do
    EM.add_periodic_timer(0.001) do
      second = Time.now.change(usec: 0).to_time
      if last_second != second.to_i
        sleep rand(1)
        last_second = second.to_i
        EM.defer do
          videos_count.times do |video_i|
            if rand(10) >= 8
              hits = rand(10) #second.to_i%10
              Stat::Site::Second.collection.update({ t: site.token, d: second }, { "$inc" => { 'vv.m' => hits } }, upsert: true)
              Stat::Video::Second.collection.update({ st: site.token, d:  "video#{video_i}", s: second }, { "$inc" => { 'vv.m' => hits } }, upsert: true)
              json = {
                site: { id: second.to_i, vv: hits },
                videos: [
                  { id: second.to_i, u: "video#{video_i}", n: "Video #{video_i}", vv: hits }
                ]
              }
              Pusher["private-#{site.token}"].trigger_async('stats', json)
            end
          end
          puts "Stats updated at #{second}"
        end
      end
    end
  end
end

def random_site_stats_inc(i, force = nil)
  {
    # field :pv, :type => Hash # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 3 }
    "pv.m"  => force || (i * rand).round,
    "pv.e"  => force || (i * rand / 2).round,
    "pv.em" => force || (i * rand / 2).round,
    "pv.d"  => force || (i * rand / 2).round,
    "pv.i"  => force || (i * rand / 2).round,
    # field :vv, :type => Hash # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 3 }
    "vv.m"  => force || (i * rand / 2).round,
    "vv.e"  => force || (i * rand / 4).round,
    "vv.em" => force || (i * rand / 4).round,
    "vv.d"  => force || (i * rand / 6).round,
    "vv.i"  => force || (i * rand / 6).round,
    # field :md, :type => Hash # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1, t (tablet) => 1 }, f (flash) => ... }
    "md.h.d" => i * rand(12),
    "md.h.m" => i * rand(5),
    "md.h.t" => i * rand(3),
    "md.f.d" => i * rand(6),
    "md.f.m" => 0, #i * rand(2),
    "md.f.t" => 0, #i * rand(2),
    # field :bp, :type => Hash # Browser + Plateform hash { "saf-win" => 2, "saf-osx" => 4, ...}
    "bp.iex-win" => i * rand(35), # 35% in total
    "bp.fir-win" => i * rand(18), # 26% in total
    "bp.fir-osx" => i * rand(8),
    "bp.chr-win" => i * rand(11), # 21% in total
    "bp.chr-osx" => i * rand(10),
    "bp.saf-win" => i * rand(1).round, # 6% in total
    "bp.saf-osx" => i * rand(5),
    "bp.saf-ipo" => i * rand(1),
    "bp.saf-iph" => i * rand(2),
    "bp.saf-ipa" => i * rand(2),
    "bp.and-and" => i * rand(6)
  }
end

def random_video_stats_inc(i, force = nil)
  {
    # field :pv, :type => Hash # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 3 }
    "vl.m"  => force || (i * rand(20)).round,
    "vl.e"  => force || (i * rand(4)).round,
    "vl.em" => force || (i * rand(2)).round,
    "vl.d"  => force || (i * rand(2)).round,
    "vl.i"  => force || (i * rand(2)).round,
    # field :vv, :type => Hash # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 3 }
    "vv.m"  => force || (i * rand(10)).round,
    "vv.e"  => force || (i * rand(3)).round,
    "vv.em" => force || (i * rand(3)).round,
    "vv.d"  => force || (i * rand(2)).round,
    "vv.i"  => force || (i * rand(2)).round,
    # field :md, :type => Hash # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1, t (tablet) => 1 }, f (flash) => ... }
    "md.h.d" => i * rand(12),
    "md.h.m" => i * rand(5),
    "md.h.t" => i * rand(3),
    "md.f.d" => i * rand(6),
    "md.f.m" => 0, #i * rand(2),
    "md.f.t" => 0, #i * rand(2),
    # field :bp, :type => Hash # Browser + Plateform hash { "saf-win" => 2, "saf-osx" => 4, ...}
    "bp.iex-win" => i * rand(35), # 35% in total
    "bp.fir-win" => i * rand(18), # 26% in total
    "bp.fir-osx" => i * rand(8),
    "bp.chr-win" => i * rand(11), # 21% in total
    "bp.chr-osx" => i * rand(10),
    "bp.saf-win" => i * rand(1).round, # 6% in total
    "bp.saf-osx" => i * rand(5),
    "bp.saf-ipo" => i * rand(1),
    "bp.saf-iph" => i * rand(2),
    "bp.saf-ipa" => i * rand(2),
    "bp.and-and" => i * rand(6)
  }
end

def create_plans
  plans_attributes = [
    { name: "free",       cycle: "none",  video_views: 0,          stats_retention_days: 0,   price: 0,     support_level: 0 },
    { name: "sponsored",  cycle: "none",  video_views: 0,          stats_retention_days: nil, price: 0,     support_level: 0 },
    { name: "plus",       cycle: "month", video_views: 200_000,    stats_retention_days: 365, price: 990,   support_level: 1 },
    { name: "premium",    cycle: "month", video_views: 1_000_000,  stats_retention_days: nil, price: 4990,  support_level: 2 },
    { name: "plus",       cycle: "year",  video_views: 200_000,    stats_retention_days: 365, price: 9900,  support_level: 1 },
    { name: "premium",    cycle: "year",  video_views: 1_000_000,  stats_retention_days: nil, price: 49900, support_level: 2 },
    { name: "custom - 1", cycle: "year",  video_views: 10_000_000, stats_retention_days: nil, price: 99900, support_level: 2 }
  ]
  plans_attributes.each { |attributes| Plan.create!(attributes) }
  puts "#{plans_attributes.size} plans created!"
end

def create_deals
  deals_attributes = [
    { token: 'rts1', name: 'Real-Time Stats promotion #1', description: 'Exclusive Newsletter Promotion: Save 20% on all yearly plans', kind: 'yearly_plans_discount', value: 0.2, availability_scope: 'newsletter', started_at: Time.now.utc.midnight, ended_at: Time.utc(2012, 2, 29).end_of_day },
    { token: 'rts2', name: 'Premium promotion #1', description: '30% discount on the Premium plan', kind: 'premium_plan_discount', value: 0.3, availability_scope: 'newsletter', started_at: 3.weeks.from_now.midnight, ended_at: 5.weeks.from_now.end_of_day }
  ]

  deals_attributes.each { |attributes| Deal.create!(attributes) }
  puts "#{deals_attributes.size} deals created!"
end

def create_mail_templates(count = 5)
  count.times do |i|
    MailTemplate.create(
      title: Faker::Lorem.sentence(1),
      subject: Faker::Lorem.sentence(1),
      body: Faker::Lorem.paragraphs(3).join("\n\n")
    )
  end
  puts "#{count} random mail templates created!"
end

def argv(var_name)
  var = ARGV.detect { |arg| arg =~ /(#{var_name}=)/i }
  if var
    var.sub($1, '')
  else
    nil
  end
end

def argv_count(var_name='count', default_count=5)
  if var = ARGV.detect { |arg| arg =~ /(#{var_name}=)/i }
    var.sub($1, '').to_i
  else
    default_count
  end
end

def argv_user(var_name='user', default_index=nil)
  if var = ARGV.detect { |arg| arg =~ /(#{var_name}=)/i }
    var.sub($1, '').to_i
  else
    default_index
  end
end

def argv_site_token(var_name='site', default_token=nil)
  if var = ARGV.detect { |arg| arg =~ /(#{var_name}=)/i }
    var.sub($1, '')
  else
    default_token
  end
end
