# coding: utf-8
require 'state_machine'
require 'ffaker' if Rails.env.development?

BASE_USERS = [["Mehdi Aminian", "mehdi@jilion.com"], ["Zeno Crivelli", "zeno@jilion.com"], ["Thibaud Guillaume-Gentil", "thibaud@jilion.com"], ["Octave Zangs", "octave@jilion.com"], ["Rémy Coutable", "remy@jilion.com"]]

namespace :db do
  
  desc "Load all development fixtures."
  task :populate => ['populate:empty_all_tables', 'populate:all']
  
  namespace :populate do
    
    desc "Empty all the tables"
    task :empty_all_tables => :environment do
      timed { empty_tables("delayed_jobs", Invoice, InvoiceItem, Log, MailTemplate, MailLog, Site, SiteUsage, User, Admin, Plan, Addon) }
    end
    
    desc "Load all development fixtures."
    task :all => :environment do
      delete_all_files_in_public('uploads/tmp')
      timed { create_admins }
      timed { create_users(argv_count) }
      timed { create_plans }
      timed { create_addons }
      timed { create_sites(argv_count) }
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
      timed { create_users(argv_count) }
    end
    
    desc "Load Site development fixtures."
    task :sites => :environment do
      timed { empty_tables(Site) }
      timed { create_sites(argv_count) }
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
    
    desc "Create fake addons"
    task :addons => :environment do
      timed { empty_tables(Plan, Addon) }
      timed { create_addons }
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
  print "#{tables.join(', ')} empty!\n"
end

def create_admins
  disable_perform_deliveries do
    print "Creating admins => "
    BASE_USERS.each do |admin_infos|
      admin = Admin.create(:full_name => admin_infos[0], :email => admin_infos[1], :password => "123456")
      admin.invitation_sent_at = Time.now
      admin.save!
      print "Admin #{admin_infos[1]}:123456 created!\n"
    end
  end
end

def create_users(count = 0)
  disable_perform_deliveries do
    BASE_USERS.each do |user_infos|
      user = User.create(
        :first_name => user_infos[0].split(' ').first,
        :last_name => user_infos[0].split(' ').second,
        :country => 'CH',
        :postal_code => '1024',
        :email => user_infos[1],
        :password => "123456",
        :use_personal => true,
        :terms_and_conditions => "1",
        :cc_type => 'visa',
        :cc_full_name => user_infos[0],
        :cc_number => "4111111111111111",
        :cc_verification_value => "111",
        :cc_expire_on => 2.years.from_now
      )
      user.confirmed_at = Time.now
      user.save!
      print "User #{user_infos[1]}:123456 created!\n"
    end
    
    count.times do |i|
      user              = User.new
      user.first_name   = Faker::Name.first_name
      user.last_name    = Faker::Name.last_name
      user.country      = 'US'
      user.postal_code  = Faker::Address.zip_code
      user.email        = Faker::Internet.email
      case rand
      when 0..0.4
        user.use_personal = true
      when 0.4..0.7
        user.use_company  = true
      when 0.7..1
        user.use_clients  = true
      end
      
      if user.use_company
        user.company_name          = Faker::Company.name
        user.company_url           = "#{rand > 0.5 ? "http://" : "www."}#{Faker::Internet.domain_name}"
        user.company_job_title     = Faker::Company.bs
        user.company_employees     = ["Company size", "1 employee", "2-5 employees", "6-20 employees", "21-100 employees", "101-1000 employees", ">1001 employees"].sample
        user.company_videos_served = ["Nr. of videos served", "0-1'000 videos/month", "1'000-10'000 videos/month", "10'000-100'000 videos/month", "100'000-1mio videos/month", ">1mio videos/month", "Don't know"].sample
      end
      
      user.password     = '123456'
      user.confirmed_at = rand(10).days.ago
      user.terms_and_conditions = "1"
      user.save
    end
    print "#{count} random users created!\n"
  end
end

def create_sites(max = 5)
  delete_all_files_in_public('uploads/licenses')
  delete_all_files_in_public('uploads/loaders')
  create_users if User.all.empty?
  create_plans if Plan.all.empty?
  plans = Plan.all
  subdomains = %w[www. blog. my. git. sv. ji. geek. yin. yang. chi. cho. chu. foo. bar. rem.]
  
  User.all.each do |user|
    rand(max).times do |i|
      site            = user.sites.build
      site.plan       = plans.sample
      site.hostname   = "#{rand > 0.5 ? '' : subdomains.sample}#{user.id}#{i}#{Faker::Internet.domain_name}"
      site.created_at = rand(500).days.ago
      site.save(:validate => false)
      site.activate
    end
  end
  print "0-#{max} random sites created for each user!\n"
end

def create_site_usages
  Site.all.each do |site|
    (30.days.ago.to_date..Date.today).each do |day|
      loader_hits                = rand(3000)
      main_player_hits           = rand(1000)
      main_player_hits_cached    = (main_player_hits * rand).to_i
      dev_player_hits            = rand(200)
      dev_player_hits_cached     = (dev_player_hits * rand).to_i
      invalid_player_hits        = rand(100)
      invalid_player_hits_cached = (invalid_player_hits * rand).to_i
      player_hits = main_player_hits + main_player_hits_cached + dev_player_hits + dev_player_hits_cached + invalid_player_hits + invalid_player_hits_cached
      
      site_usage = SiteUsage.new(:day => day, :site_id => site.id)
      site_usage.loader_hits = loader_hits
      site_usage.main_player_hits           = main_player_hits
      site_usage.main_player_hits_cached    = main_player_hits_cached
      site_usage.dev_player_hits            = dev_player_hits
      site_usage.dev_player_hits_cached     = dev_player_hits_cached
      site_usage.invalid_player_hits        = invalid_player_hits
      site_usage.invalid_player_hits_cached = invalid_player_hits_cached
      site_usage.player_hits                = player_hits
      site_usage.flash_hits                 = (player_hits * rand / 3).to_i
      site_usage.requests_s3                = player_hits - (main_player_hits_cached + dev_player_hits_cached + invalid_player_hits_cached)
      site_usage.traffic_s3                 = site_usage.requests_s3 * 150000 # 150 KB
      site_usage.traffic_voxcast            = player_hits * 150000
      
      site_usage.save
      
      puts "#{player_hits} video-page views on #{day} for site ##{site.id}!"
    end
  end
end

def create_plans
  plans = [
    { :name => "perso",      :player_hits => 3000,   :price => 299,  :overage_price => 299 },
    { :name => "pro",        :player_hits => 30000,  :price => 999,  :overage_price => 199 },
    { :name => "enterprise", :player_hits => 300000, :price => 4999, :overage_price => 99 },
  ]
  plans.each { |attributes| Plan.create(attributes) }
  print "#{plans.size} plans created!\n"
end

def create_addons
  create_plans if Plan.all.empty?
  addons = [
    { :name => "ssl", :price => 499 }
  ]
  addons.each { |attributes| Addon.create(attributes) }
  print "#{addons.size} addon(s) created!\n"
end

def create_mail_templates(count = 5)
    count.times do |i|
      mail_template            = MailTemplate.new
      mail_template.title      = Faker::Lorem.sentence(1)
      mail_template.subject    = Faker::Lorem.sentence(1)
      mail_template.body       = Faker::Lorem.paragraphs(3).join("\n\n")
      mail_template.created_at = rand(50).days.ago
      mail_template.save!
    end
  print "#{count} random mail templates created!\n"
end

def argv_count
  ARGV.size > 1 ? ARGV[1].sub(/COUNT=/, '').to_i : 5
end