# coding: utf-8
require 'state_machine'
require 'ffaker' if Rails.env.development?

BASE_USERS = [["Mehdi Aminian", "mehdi@jilion.com"], ["Zeno Crivelli", "zeno@jilion.com"], ["Thibaud Guillaume-Gentil", "thibaud@jilion.com"], ["Octave Zangs", "octave@jilion.com"], ["Rémy Coutable", "remy@jilion.com"]]
COUNTRIES = %w[US FR CH ES DE BE GB CN SE NO FI BR CA]
BASE_SITES = %w[vimeo.com dribbble.com jilion.com swisslegacy.com maxvoltar.com 37signals.com zeldman.com sumagency.com deaxon.com veerle.duoh.com]

namespace :db do

  desc "Load all development fixtures."
  task :populate => ['populate:empty_all_tables', 'populate:all']

  namespace :populate do
    desc "Empty all the tables"
    task :empty_all_tables => :environment do
      timed { empty_tables("delayed_jobs", Invoice, InvoiceItem, Log, MailTemplate, MailLog, Site, SiteUsage, User, Admin, Plan) }
    end

    desc "Load all development fixtures."
    task :all => :environment do
      delete_all_files_in_public('uploads/releases')
      delete_all_files_in_public('uploads/s3')
      delete_all_files_in_public('uploads/tmp')
      delete_all_files_in_public('uploads/voxcast')
      timed { create_admins }
      timed { create_users(argv_index) }
      timed { create_plans }
      timed { create_sites }
      timed { create_site_usages }
      timed { create_mail_templates }
    end

    desc "Load Admin development fixtures."
    task :admins => :environment do
      timed { empty_tables(Admin) }
      timed { create_admins }
    end

    desc "Load User development fixtures."
    task :users => :environment do
      timed { empty_tables(Site, User) }
      timed { create_users(argv_index) }
      empty_tables("delayed_jobs")
    end

    desc "Load Site development fixtures."
    task :sites => :environment do
      timed { empty_tables(Site) }
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

def create_users(index=nil)
  created_at_array = (Date.new(2010,9,14)..100.days.ago.to_date).to_a
  disable_perform_deliveries do
    (index ? index.upto(index) : 0.upto(BASE_USERS.count - 1)).each do |i|
      user = User.new(
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
        cc_type: 'visa',
        cc_full_name: BASE_USERS[i][0],
        cc_number: "4111111111111111",
        cc_verification_value: "111",
        cc_expire_on: 2.years.from_now
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

    # count.times do |i|
    #   user = User.new(
    #     first_name: Faker::Name.first_name,
    #     last_name: Faker::Name.last_name,
    #     country: COUNTRIES.sample,
    #     postal_code: Faker::Address.zip_code,
    #     email: Faker::Internet.email,
    #     use_personal: use_personal,
    #     use_company: use_company,
    #     use_clients: use_clients,
    #     password: '123456',
    #     terms_and_conditions: "1",
    #     company_name: Faker::Company.name,
    #     company_url: "#{rand > 0.5 ? "http://" : "www."}#{Faker::Internet.domain_name.sub(/(\.co)?\.uk/, '.be')}",
    #     company_job_title: Faker::Company.bs,
    #     company_employees: ["1 employee", "2-5 employees", "6-20 employees", "21-100 employees", "101-1000 employees", ">1001 employees"].sample,
    #     company_videos_served: ["0-1'000 videos/month", "1'000-10'000 videos/month", "10'000-100'000 videos/month", "100'000-1mio videos/month", ">1mio videos/month", "Don't know"].sample
    #   )
    #
    #   if rand > 0.3
    #     user.cc_type = 'visa'
    #     user.cc_full_name = user.full_name
    #     user.cc_number = "4111111111111111"
    #     user.cc_verification_value = "111"
    #     user.cc_expire_on = 2.years.from_now
    #   end
    #   user.created_at   = created_at_array.sample
    #   user.confirmed_at = user.created_at
    #   user.save!(validate: false)
    # end
    # puts "+ #{count} random users created!"
  end
end

def create_sites
  delete_all_files_in_public('uploads/licenses')
  delete_all_files_in_public('uploads/loaders')
  create_users if User.all.empty?
  create_plans if Plan.all.empty?
  plan_ids = Plan.all.map(&:id)
  subdomains = %w[www blog my git sv ji geek yin yang chi cho chu foo bar rem]
  created_at_array = (Date.new(2010,9,14)..(1.month.ago - 2.days).to_date).to_a

  require 'invoice_item/plan' # FIXME WHY OH WHY !??!!!

  User.all.each do |user|
    BASE_SITES.each do |hostname|
      site = user.sites.build(
        plan_id: plan_ids.sample,
        hostname: hostname
      )
      Timecop.travel(created_at_array.sample) do
        site.save! # TODO: USe VCR here to avoid calls to Ogone?!
      end
      site.cdn_up_to_date = true if rand > 0.5
      site.apply_pending_plan_changes
    end
  end
  puts "#{BASE_SITES.size} beautiful sites created for each user!"
end

def create_site_usages
  start_date = Date.new(2010,9,14)
  end_date   = Date.today
  player_hits_total = 0
  Site.active.each do |site|
    p = (case rand(4)
    when 0
      site.plan.player_hits/30.0 - (site.plan.player_hits/30.0 / 2)
    when 1
      site.plan.player_hits/30.0 - (site.plan.player_hits/30.0 / 4)
    when 2
      site.plan.player_hits/30.0 + (site.plan.player_hits/30.0 / 4)
    when 3
      site.plan.player_hits/30.0 + (site.plan.player_hits/30.0 / 2)
    end).to_i

    (start_date..end_date).each do |day|
      Timecop.travel(day) do
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
          day: day.to_time.utc.midnight,
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
  end
  puts "#{player_hits_total} video-page views total created between #{start_date} and #{end_date}!"
end

def create_plans
  plans_attributes = [
    { name: "dev",        cycle: "none",  player_hits: 0,          price: 0 },
    { name: "sponsored",  cycle: "none",  player_hits: 0,          price: 0 },
    { name: "beta",       cycle: "none",  player_hits: 0,          price: 0 },
    { name: "comet",      cycle: "month", player_hits: 3_000,      price: 990 },
    { name: "planet",     cycle: "month", player_hits: 50_000,     price: 1990 },
    { name: "star",       cycle: "month", player_hits: 200_000,    price: 4990 },
    { name: "galaxy",     cycle: "month", player_hits: 1_000_000,  price: 9990 },
    { name: "comet",      cycle: "year",  player_hits: 3_000,      price: 9900 },
    { name: "planet",     cycle: "year",  player_hits: 50_000,     price: 19900 },
    { name: "star",       cycle: "year",  player_hits: 200_000,    price: 49900 },
    { name: "galaxy",     cycle: "year",  player_hits: 1_000_000,  price: 99900 },
    { name: "custom1",    cycle: "year",  player_hits: 10_000_000, price: 999900 }
  ]
  plans_attributes.each { |attributes| Plan.create(attributes) }
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

def argv_index(var_name='index', default_index=nil)
  if var = ARGV.detect { |arg| arg =~ /(#{var_name}=)/i }
    var.sub($1, '').to_i
  else
    default_index
  end
end

def argv_count(var_name='count', default_count=5)
  if var = ARGV.detect { |arg| arg =~ /(#{var_name}=)/i }
    var.sub($1, '').to_i
  else
    default_count
  end
end
