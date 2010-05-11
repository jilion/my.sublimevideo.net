require 'state_machine'
require 'ffaker'

BASE_USERS = [["Mehdi Aminian", "mehdi@jilion.com"], ["Zeno Crivelli", "zeno@jilion.com"], ["Thibaud Guillaume-Gentil", "thibaud@jilion.com"], ["Octave Zangs", "octave@jilion.com"], ["Rémy Coutable", "remy@jilion.com"]]

namespace :db do
  
  desc "Load all development fixtures."
  task :populate => ['populate:empty_all_tables', 'populate:all']
  
  namespace :populate do
    
    desc "Empty all the tables"
    task :empty_all_tables => :environment do
      empty_tables(Site, User)
    end
    
    desc "Load all development fixtures."
    task :all => :environment do
      create_users
      create_sites
    end
    
    desc "Load User development fixtures."
    task :users => :environment do
      empty_tables(Site, User)
      create_users((ARGV.size > 1 ? ARGV[1].sub(/COUNT=/, '').to_i : 5))
    end
    
    desc "Load Site development fixtures."
    task :sites => :environment do
      empty_tables(Site)
      create_sites((ARGV.size > 1 ? ARGV[1].sub(/COUNT=/, '').to_i : 5))
    end
    
  end
  
end

private

def empty_tables(*tables)
  print "Deleting the content of #{tables.join(', ')}.. => "
  tables.map(&:delete_all)
  print "#{tables.join(', ')} empty!\n\n"
end

def create_admins
  disable_perform_deliveries do
    print "Creating admins => "
    BASE_USERS.each do |admin_infos|
      admin = Admin.create(:full_name => admin_infos[0], :email => admin_infos[1], :password => "123456")
      admin.confirmed_at = Time.now
      admin.save!
      print "#{admin_infos[1]}/123456 created!\n\n"
    end
  end
end

def create_users(count = 5)
  disable_perform_deliveries do
    
    BASE_USERS.each do |user_infos|
      user = User.create(:full_name => user_infos[0], :email => user_infos[1], :password => "123456")
      user.confirmed_at = Time.now
      user.save!
      print "#{user_infos[1]}/123456 created!\n\n"
    end
    
    count.times do |i|
      user                       = User.new
      user.full_name             = Faker::Name.name
      user.email                 = Faker::Internet.email
      user.password              = '123456'
      user.confirmed_at          = rand(10).days.ago
      user.save!
    end
    print "#{count} random users created!\n\n"
  end
end

def create_sites(count = 5)
  create_users if User.all.empty?
  
  User.all.each do |user|
    count.times do |i|
      site               = user.sites.build
      site.hostname      = "#{rand > 0.5 ? '' : %w[www. blog. my. git. sv. ji. geek.].rand}#{Faker::Internet.domain_name}"
      site.dev_hostnames = "localhost, 127.0.0.1"
      site.token         = (rand*10000000).to_i.to_s(32)
      site.state         = Site::STATES.rand
      site.created_at    = rand(1500).days.ago
      site.save!
    end
  end
  print "#{count} random sites created for each user!\n\n"
end

def disable_perform_deliveries(&block)
  if block_given?
    original_perform_deliveries = ActionMailer::Base.perform_deliveries
    # Disabling perform_deliveries (avoid to spam fakes email adresses)
    ActionMailer::Base.perform_deliveries = false
    
    yield
    
    # Switch back to the original perform_deliveries
    ActionMailer::Base.perform_deliveries = original_perform_deliveries
  else
    put "\n\nYou should pass a block to this method!\n\n"
  end
end