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
      timed { create_sites }
    end
    
    desc "Load User development fixtures."
    task :users => :environment do
      timed { empty_tables(Site, User) }
      timed { create_users(argv_count) }
    end
    
    desc "Load Admin development fixtures."
    task :admins => :environment do
      timed { empty_tables(Admin) }
      timed { create_admins }
    end
    
    desc "Load Site development fixtures."
    task :sites => :environment do
      timed { empty_tables(Site) }
      timed { create_sites }
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
      user = User.create(:full_name => user_infos[0], :email => user_infos[1], :password => "123456")
      user.confirmed_at = Time.now
      user.save!
      print "User #{user_infos[1]}:123456 created!\n"
    end
    
    count.times do |i|
      user              = User.new
      user.full_name    = Faker::Name.name
      user.email        = Faker::Internet.email
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
      site.hostname   = "#{rand > 0.5 ? '' : %w[www. blog. my. git. sv. ji. geek.].sample}#{Faker::Internet.domain_name}"
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

def argv_count
  ARGV.size > 1 ? ARGV[1].sub(/COUNT=/, '').to_i : 5
end