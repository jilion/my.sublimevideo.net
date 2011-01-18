# coding: utf-8
require 'state_machine'
require 'ffaker' if Rails.env.development?

BASE_USERS = [["Mehdi Aminian", "mehdi@jilion.com"], ["Zeno Crivelli", "zeno@jilion.com"], ["Thibaud Guillaume-Gentil", "thibaud@jilion.com"], ["Octave Zangs", "octave@jilion.com"], ["Rémy Coutable", "remy@jilion.com"]]
COUNTRIES = %w[US FR CH ES DE BE UK CN SE NO FI BR CA]

namespace :db do

  desc "Load all development fixtures."
  task populate: ['populate:empty_all_tables', 'populate:all']

  namespace :populate do

    desc "Empty all the tables"
    task empty_all_tables: :environment do
      timed { empty_tables("delayed_jobs", Invoice, InvoiceItem, Log, MailTemplate, MailLog, Site, SiteUsage, User, Admin, Plan, Addon) }
    end

    desc "Load all development fixtures."
    task all: :environment do
      delete_all_files_in_public('uploads/releases')
      delete_all_files_in_public('uploads/s3')
      delete_all_files_in_public('uploads/tmp')
      delete_all_files_in_public('uploads/voxcast')
      timed { create_admins }
      timed { create_users(argv_count) }
      timed { create_plans }
      timed { create_addons }
      timed { create_sites(argv_count) }
      timed { create_site_usages }
      timed { create_invoices(argv_count) }
      timed { create_mail_templates }
    end

    desc "Load Admin development fixtures."
    task admins: :environment do
      timed { empty_tables(Admin) }
      timed { create_admins }
    end

    desc "Load User development fixtures."
    task users: :environment do
      timed { empty_tables(Site, User) }
      timed { create_users(argv_count) }
      empty_tables("delayed_jobs")
    end

    desc "Load Site development fixtures."
    task sites: :environment do
      timed { empty_tables(Site) }
      timed { create_sites(argv_count) }
      empty_tables("delayed_jobs")
    end

    desc "Load Mail templates development fixtures."
    task mail_templates: :environment do
      timed { empty_tables(MailTemplate) }
      timed { create_mail_templates }
    end

    desc "Create fake usages"
    task site_usages: :environment do
      timed { empty_tables(SiteUsage) }
      timed { create_site_usages }
    end

    desc "Create fake invoices"
    task invoices: :environment do
      timed { empty_tables(Invoice) }
      timed { create_invoices(argv_count) }
      # empty_tables("delayed_jobs")
    end

    desc "Create fake plans"
    task plans: :environment do
      timed { empty_tables(Plan) }
      timed { create_plans }
    end

    desc "Create fake addons"
    task addons: :environment do
      timed { empty_tables(Plan, Addon) }
      timed { create_addons }
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
    BASE_USERS.each do |admin_infos|
      admin = Admin.create(full_name: admin_infos[0], email: admin_infos[1], password: "123456")
      # admin.invitation_sent_at = Time.now
      admin.save!
      puts "Admin #{admin_infos[1]}:123456"
    end
  end
end

def create_users(count)
  created_at_array = (Date.new(2010,9,14)..Date.today).to_a
  disable_perform_deliveries do
    BASE_USERS.each do |user_infos|
      user = User.new(
        first_name: user_infos[0].split(' ').first,
        last_name: user_infos[0].split(' ').second,
        country: COUNTRIES.sample,
        postal_code: Faker::Address.zip_code,
        email: user_infos[1],
        password: "123456",
        use_personal: true,
        terms_and_conditions: "1",
        cc_type: 'visa',
        cc_full_name: user_infos[0],
        cc_number: "4111111111111111",
        cc_verification_value: "111",
        cc_expire_on: 2.years.from_now
      )
      user.created_at   = created_at_array.sample
      user.confirmed_at = user.created_at
      user.save!(validate: false)
      puts "User #{user_infos[1]}:123456"
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

    count.times do |i|
      user = User.new(
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        country: COUNTRIES.sample,
        postal_code: Faker::Address.zip_code,
        email: Faker::Internet.email,
        use_personal: use_personal,
        use_company: use_company,
        use_clients: use_clients,
        password: '123456',
        terms_and_conditions: "1",
        company_name: Faker::Company.name,
        company_url: "#{rand > 0.5 ? "http://" : "www."}#{Faker::Internet.domain_name.sub(/(\.co)?\.uk/, '.be')}",
        company_job_title: Faker::Company.bs,
        company_employees: ["1 employee", "2-5 employees", "6-20 employees", "21-100 employees", "101-1000 employees", ">1001 employees"].sample,
        company_videos_served: ["0-1'000 videos/month", "1'000-10'000 videos/month", "10'000-100'000 videos/month", "100'000-1mio videos/month", ">1mio videos/month", "Don't know"].sample
      )
      
      if rand > 0.3
        user.cc_type = 'visa'
        user.cc_full_name = user.full_name
        user.cc_number = "4111111111111111"
        user.cc_verification_value = "111"
        user.cc_expire_on = 2.years.from_now
      end
      user.created_at   = created_at_array.sample
      user.confirmed_at = user.created_at
      user.save!(validate: false)
    end
    puts "+ #{count} random users created!"
  end
end

def create_sites(max)
  delete_all_files_in_public('uploads/licenses')
  delete_all_files_in_public('uploads/loaders')
  create_users if User.all.empty?
  create_plans if Plan.all.empty?
  plan_ids = Plan.all.map(&:id)
  subdomains = %w[www blog my git sv ji geek yin yang chi cho chu foo bar rem]
  created_at_array = (Date.new(2010,9,14)..10.days.ago.to_date).to_a
  ssl_addon_id = Addon.find_by_name('ssl')

  User.all.each do |user|
    rand(max).times do |i|
      site = user.sites.build(
        plan_id: plan_ids.sample,
        hostname: subdomains.sample + (rand > 0.75 ? "." : "") + user.id.to_s + i.to_s + Faker::Internet.domain_name.sub(/(\.co)?\.uk/, '.be'),
        addon_ids: rand > 0.75 ? [ssl_addon_id] : []
      )
      site.state        = 'active' if user.cc? && rand > 0.2
      site.created_at   = [user.confirmed_at.to_date, created_at_array.sample].max
      site.activated_at = site.created_at if site.active?

      Timecop.travel(site.created_at) do
        site.save!(validate: false)
      end
    end
  end
  puts "0-#{max} random sites created for each user!"
end

def create_site_usages
  start_date = Date.new(2010,9,14)
  end_date   = Date.today
  player_hits_total = 0
  i = rand(1000)
  Site.active.each do |site|
    (start_date..end_date).each do |day|
      r = i % 4
      p = (case r
      when 0
        site.plan.player_hits/30.0 - (site.plan.player_hits/30.0 / 2)
      when 1
        site.plan.player_hits/30.0 - (site.plan.player_hits/30.0 / 4)
      when 2
        site.plan.player_hits/30.0 + (site.plan.player_hits/30.0 / 4)
      when 3
        site.plan.player_hits/30.0 + (site.plan.player_hits/30.0 / 2)
      end).to_i
      i += rand(1000)
      
      loader_hits                = p * rand(100)
      main_player_hits           = p * 0.6
      main_player_hits_cached    = p * 0.4
      dev_player_hits            = rand(100)
      dev_player_hits_cached     = (dev_player_hits * rand).to_i
      invalid_player_hits        = rand(500)
      invalid_player_hits_cached = (invalid_player_hits * rand).to_i
      player_hits = main_player_hits + main_player_hits_cached + dev_player_hits + dev_player_hits_cached + invalid_player_hits + invalid_player_hits_cached
      requests_s3 = player_hits - (main_player_hits_cached + dev_player_hits_cached + invalid_player_hits_cached)

      site_usage = SiteUsage.new(
        day: day,
        site_id: site.id,
        loader_hits: loader_hits,
        main_player_hits: main_player_hits,
        main_player_hits_cached: main_player_hits_cached,
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
  puts "#{player_hits_total} video-page views total created between #{start_date} and #{end_date}!"
end

def create_invoices(count = 5)
  d = Site.minimum(:created_at)
  while d < Time.now.beginning_of_month
    Invoice.complete_invoices_for_billable_users(d.beginning_of_month, d.end_of_month)
    d += 1.month
  end
  # end
  puts "#{Invoice.count} invoices created!"
end

def create_plans
  plans_attributes = [
    { name: "perso",      player_hits: 3000,    price: 299,  overage_price: 299 },
    { name: "pro",        player_hits: 100000,  price: 999,  overage_price: 199 },
    { name: "enterprise", player_hits: 1000000, price: 6999, overage_price: 99 }
  ]
  plans_attributes.each { |attributes| Plan.create(attributes) }
  puts "#{plans_attributes.size} plans created!"
end

def create_addons
  create_plans if Plan.all.empty?
  addons_attributes = [
    { name: "ssl", price: 499 }
  ]
  addons_attributes.each { |attributes| Addon.create(attributes) }
  puts "#{addons_attributes.size} addon(s) created!"
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

def argv_count
  ARGV.size > 1 ? ARGV[1].sub(/COUNT=/, '').to_i : 5
end
