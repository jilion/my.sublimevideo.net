# coding: utf-8
require 'state_machine'
require 'ffaker' if Rails.env.development?

BASE_USERS = [["Mehdi Aminian", "mehdi@jilion.com"], ["Zeno Crivelli", "zeno@jilion.com"], ["Thibaud Guillaume-Gentil", "thibaud@jilion.com"], ["Octave Zangs", "octave@jilion.com"], ["Rémy Coutable", "remy@jilion.com"]]
COUNTRIES = %w[US FR CH ES DE BE GB CN SE NO FI BR CA]
BASE_SITES = %w[vimeo.com dribbble.com jilion.com swisslegacy.com maxvoltar.com 37signals.com youtube.com zeldman.com sumagency.com deaxon.com veerle.duoh.com]
# BASE_SITES = %w[sublimevideo.net jilion.com swisslegacy.com]

namespace :db do

  desc "Load all development fixtures."
  task :populate => ['populate:empty_all_tables', 'populate:all']

  namespace :populate do
    desc "Empty all the tables"
    task :empty_all_tables => :environment do
      timed { empty_tables("delayed_jobs", "invoices_transactions", InvoiceItem, Invoice, Transaction, Log, MailTemplate, MailLog, Site, SiteUsage, User, Admin, Plan) }
    end

    desc "Load all development fixtures."
    task :all => :environment do
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
      timed { create_mail_templates }
    end

    desc "Load Admin development fixtures."
    task :admins => :environment do
      timed { empty_tables(Admin) }
      timed { create_admins }
    end

    desc "Load User development fixtures."
    task :users => :environment do
      timed { empty_tables("invoices_transactions", InvoiceItem, Invoice, Transaction, Site, User) }
      timed { create_users(argv_user) }
      empty_tables("delayed_jobs")
    end

    desc "Load Site development fixtures."
    task :sites => :environment do
      timed { empty_tables("invoices_transactions", InvoiceItem, Invoice, Transaction, Site) }
      timed { create_sites }
      empty_tables("delayed_jobs")
    end

    desc "Load Mail templates development fixtures."
    task :mail_templates => :environment do
      timed { empty_tables(MailTemplate) }
      timed { create_mail_templates }
    end

    desc "Create fake usages"
    task :site_usages => :environment do
      timed { empty_tables(SiteUsage) }
      timed { create_site_usages }
    end

    desc "Create fake site stats"
    task :site_stats => :environment do
      timed { empty_tables(SiteStat) }
      timed { create_site_stats(argv_user) }
    end

    desc "Create fake site stats"
    task :recurring_site_stats => :environment do
      timed { empty_tables(SiteStat) }
      timed { create_site_stats(argv_user) }
      timed { recurring_site_stats_update(argv_user) }
    end

    desc "Create fake plans"
    task :plans => :environment do
      timed { empty_tables(Plan) }
      timed { create_plans }
    end

  end

end

namespace :user do

  desc "Expire the credit card of the user with the given email (EMAIL=xx@xx.xx) at the end of the month (or the opposite if already expiring at the end of the month)"
  task :cc_will_expire => :environment do
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
          cc_full_name: user.full_name,
          cc_number: "4111111111111111",
          cc_verification_value: "111",
          cc_expire_on: date
        })
      end
    end
  end

  desc "Suspend/unsuspend a user given an email (EMAIL=xx@xx.xx), you can pass the count of failed invoices on suspend with FAILED_INVOICES=N"
  task :suspended => :environment do
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
  task :draw => :environment do
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
    BASE_USERS.each do |admin_infos|
      Admin.create(full_name: admin_infos[0], email: admin_infos[1], password: "123456")
      puts "Admin #{admin_infos[1]}:123456"
    end
  end
end

def create_users(user_id=nil)
  created_at_array = (Date.new(2011,1,1)..100.days.ago.to_date).to_a
  disable_perform_deliveries do
    (user_id ? [user_id] : 0.upto(BASE_USERS.count - 1)).each do |i|
      user = User.new(
        enthusiast_id: rand(1000000),
        first_name: BASE_USERS[i][0].split(' ').first,
        last_name: BASE_USERS[i][0].split(' ').second,
        country: COUNTRIES.sample,
        postal_code: Faker::Address.zip_code,
        email: BASE_USERS[i][1],
        password: "123456",
        use_personal: true,
        terms_and_conditions: "1"
      )
      user.created_at   = created_at_array.sample
      user.confirmed_at = user.created_at
      user.save!(validate: false)
      user.attributes = {
        cc_brand: 'visa',
        cc_full_name: BASE_USERS[i][0],
        cc_number: "4111111111111111",
        cc_verification_value: "111",
        cc_expiration_month: 2.years.from_now.month,
        cc_expiration_year: 2.years.from_now.year
      }
      user.check_credit_card
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

  unpaid_plans   = Plan.unpaid_plans.where { name != "sponsored" }.all
  standard_plans = Plan.standard_plans.all
  custom_plans   = Plan.custom_plans.all

  subdomains = %w[www blog my git sv ji geek yin yang chi cho chu foo bar rem]
  created_at_array = (Date.new(2010,1,1)..(1.month.ago - 2.days).to_date).to_a

  require 'invoice_item/plan'

  User.all.each do |user|
    BASE_SITES.each do |hostname|
      site = user.sites.build(
        plan_id: rand > 0.4 ? (rand > 0.8 ? custom_plans.sample.token : standard_plans.sample.id) : unpaid_plans.sample.id,
        hostname: hostname
      )
      Timecop.travel(created_at_array.sample) do
        site.save_without_password_validation
      end

      if rand > 0.5
        site.cdn_up_to_date = true
        site.save_without_password_validation
      end
      site.sponsor! if rand > 0.85
    end
  end

  Site.activate_or_downgrade_sites_leaving_trial
  Invoice.open.all.each { |invoice| invoice.succeed! }

  puts "#{BASE_SITES.size} beautiful sites created for each user!"
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

def create_site_stats(user_id=nil)
  users = user_id ? [User.find(user_id)] : User.all
  users.each do |user|
    user.sites.each do |site|
      # Days
      95.times.each do |i|
        SiteStat.collection.update(
          { t: site.token, d: i.days.ago.change(hour: 0, min: 0, sec: 0, usec: 0).to_time },
          { "$inc" => random_stats_inc(24 * 60 * 60) },
          upsert: true
        )
      end
      # Hours
      25.times.each do |i|
        SiteStat.collection.update(
          { t: site.token, h: i.hours.ago.change(min: 0, sec: 0, usec: 0).to_time },
          { "$inc" => random_stats_inc(60 * 60) },
          upsert: true
        )
      end
      # Minutes
      60.times.each do |i|
        SiteStat.collection.update(
          { t: site.token, m: i.minutes.ago.change(sec: 0, usec: 0).to_time },
          { "$inc" => random_stats_inc(60) },
          upsert: true
        )
      end
      # seconds
      60.times.each do |i|
        SiteStat.collection.update(
          { t: site.token, s: i.seconds.ago.change(usec: 0).to_time },
          { "$inc" => random_stats_inc(1) },
          upsert: true
        )
      end
    end
  end
  puts "Fake site(s) stats generated"
end

def recurring_site_stats_update(user_id)
  sites = User.find(user_id).sites
  puts "Begin recurring fake site(s) stats generation (each minute)"
  Thread.new do
    loop do
      second = Time.now.utc.change(usec: 0).to_time
      sites.each do |site|
        inc = random_stats_inc(1)
        SiteStat.collection.update({ t: site.token, s: second }, { "$inc" => inc }, upsert: true)
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
          inc = random_stats_inc(60)
          SiteStat.collection.update({ t: site.token, m: (now - 1.minute).change(sec: 0, usec: 0).to_time },                  { "$inc" => inc }, upsert: true)
          SiteStat.collection.update({ t: site.token, h: (now - 1.minute).change(min: 0, sec: 0, usec: 0).to_time },          { "$inc" => inc }, upsert: true)
          SiteStat.collection.update({ t: site.token, d: (now - 1.minute).change(hour: 0, min: 0, sec: 0, usec: 0).to_time }, { "$inc" => inc }, upsert: true)
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
        Pusher["presence-#{site.token}"].trigger_async('stats', json.merge('id' => second.to_i))
        json = { "md" => { "f" => { "d" => 1 }, "h" => { "d" => 1 } } }
        Pusher["presence-#{site.token}"].trigger_async('stats', json.merge('id' => second.to_i))
        json = { "vv" => 1 }
        Pusher["presence-#{site.token}"].trigger_async('stats', json.merge('id' => second.to_i))
      end
    end
  end
end

def random_stats_inc(i, force = nil)
  {
    # field :pv, :type => Hash # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2 }
    "pv.m" => force || (i * rand(20)),
    "pv.e" => force || (i * rand(4)),
    "pv.d" => force || (i * rand(2)),
    "pv.i" => force || (i * rand(2)),
    # field :vv, :type => Hash # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1 }
    "vv.m" => force || (i * rand(10)),
    "vv.e" => force || (i * rand(3)),
    "vv.d" => force || (i * rand(2)),
    "vv.i" => force || (i * rand(2)),
    # field :md, :type => Hash # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
    "md.h.d" => i * rand(12),
    "md.h.m" => i * rand(5),
    "md.h.t" => i * rand(3),
    "md.f.d" => i * rand(6),
    "md.f.m" => 0, #i * rand(2),
    "md.f.t" => 0, #i * rand(2),
    # field :bp, :type => Hash # Browser + Plateform hash { "saf-win" => 2, "saf-osx" => 4, ...}
    "bp.iex-win" => i * rand(30),
    "bp.fir-win" => i * rand(30),
    "bp.chr-win" => i * rand(40),
    "bp.saf-win" => i * rand(2),
    "bp.saf-osx" => i * rand(9),
    "bp.chr-osx" => i * rand(12),
    "bp.fir-osx" => i * rand(5),
    "bp.saf-ipo" => i * rand(2),
    "bp.saf-iph" => i * rand(8),
    "bp.saf-ipa" => i * rand(5),
    "bp.and-and" => i * rand(6)
  }
end

def create_plans
  plans_attributes = [
    { name: "free",       cycle: "none",  video_views: 0,          stats_retention_days: 0,   price: 0,     support_level: 0 },
    { name: "sponsored",  cycle: "none",  video_views: 0,          stats_retention_days: nil, price: 0,     support_level: 0 },
    { name: "silver",     cycle: "month", video_views: 200_000,    stats_retention_days: 365, price: 990,   support_level: 1 },
    { name: "gold",       cycle: "month", video_views: 1_000_000,  stats_retention_days: nil, price: 4990,  support_level: 2 },
    { name: "silver",     cycle: "year",  video_views: 200_000,    stats_retention_days: 365, price: 9900,  support_level: 1 },
    { name: "gold",       cycle: "year",  video_views: 1_000_000,  stats_retention_days: nil, price: 49900, support_level: 2 },
    { name: "custom1",    cycle: "year",  video_views: 10_000_000, stats_retention_days: nil, price: 99900, support_level: 2 }
  ]
  plans_attributes.each { |attributes| Plan.create!(attributes) }
  puts "#{plans_attributes.size} plans created!"
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

