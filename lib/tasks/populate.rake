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
      timed { empty_tables("delayed_jobs", Invoice, Log, SiteUsage, Site, User, Admin) }
    end
    
    desc "Load all development fixtures."
    task :all => :environment do
      delete_all_files_in_public('uploads/tmp')
      timed { create_admins }
      timed { create_users(argv_count) }
      timed { create_sites(argv_count) }
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
      timed { empty_tables(Mail::Template) }
      timed { create_mail_templates }
    end
    
    desc "Create fake usages"
    task :usages => :environment do
      timed do
        empty_tables(SiteUsage)
        Site.all.each do |site|
          (30.days.ago.to_date..Date.today).each do |day|
            loader_hits                = rand(3000)
            main_player_hits           = rand(1000)
            main_player_hits_cached    = (main_player_hits * rand).to_i
            dev_player_hits            = rand(200)
            dev_player_hits_cached     = (dev_player_hits * rand).to_i
            invalid_player_hits        = rand(100)
            invalid_player_hits_cached = (invalid_player_hits * rand).to_i
            player_hits = loader_hits + main_player_hits + main_player_hits_cached + dev_player_hits + dev_player_hits_cached + invalid_player_hits + invalid_player_hits_cached
            
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
    end
    
  end
  
end

namespace :sm do
  
  desc "Draw the States Diagrams for every model having State Machine"
  task :draw => :environment do
    %x(rake state_machine:draw CLASS=Invoice,Log,Site,User TARGET=doc/state_diagrams FORMAT=jpg ORIENTATION=landscape)
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
        :password => "123456"
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
      user.use_personal = rand > 0.5
      user.use_company  = rand > 0.5
      user.use_clients  = user.use_company && rand > 0.3
      
      if user.use_company
        user.company_name          = Faker::Company.name
        user.company_url           = "#{rand > 0.5 ? "http://" : "www."}#{Faker::Internet.domain_name}"
        user.company_job_title     = Faker::Company.bs
        user.company_employees     = ["Company size", "1 employee", "2-5 employees", "6-20 employees", "21-100 employees", "101-1000 employees", ">1001 employees"].sample
        user.company_videos_served = ["Nr. of videos served", "0-1'000 videos/month", "1'000-10'000 videos/month", "10'000-100'000 videos/month", "100'000-1mio videos/month", ">1mio videos/month", "Don't know"].sample
      end
      
      user.password     = '123456'
      user.confirmed_at = rand(10).days.ago
      user.save
    end
    print "#{count} random users created!\n"
  end
end

def create_sites(max = 5)
  delete_all_files_in_public('uploads/licenses')
  delete_all_files_in_public('uploads/loaders')
  create_users if User.all.empty?
  
  User.all.each do |user|
    rand(max).times do |i|
      site            = user.sites.build
      site.hostname   = "#{rand > 0.5 ? '' : %w[www. blog. my. git. sv. ji. geek. yin. yang. chi. cho. chu. foo. bar. rem.].sample}#{user.id}#{i}#{Faker::Internet.domain_name}"
      site.created_at = rand(1500).days.ago
      site.flash_hits_cache  = rand(1000)
      site.player_hits_cache = rand(500) + site.flash_hits_cache
      site.loader_hits_cache = rand(10000) + site.player_hits_cache
      site.save!
      site.activate
    end
  end
  print "0-#{max} random sites created for each user!\n"
end

def create_mail_templates(count = 5)
    count.times do |i|
      mail_template            = Mail::Template.new
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