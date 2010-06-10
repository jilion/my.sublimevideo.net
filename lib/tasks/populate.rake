require 'state_machine'
require 'ffaker'

BASE_USERS = [["Mehdi Aminian", "mehdi@jilion.com"], ["Zeno Crivelli", "zeno@jilion.com"], ["Thibaud Guillaume-Gentil", "thibaud@jilion.com"], ["Octave Zangs", "octave@jilion.com"], ["Rémy Coutable", "remy@jilion.com"]]
FORMATS    = %w[Desktop 3G WiFi Ogg]

namespace :db do
  
  desc "Load all development fixtures."
  task :populate => ['populate:empty_all_tables', 'populate:all']
  
  namespace :populate do
    
    desc "Empty all the tables"
    task :empty_all_tables => :environment do
      timed { empty_tables(Video, Site, User) }
    end
    
    desc "Load all development fixtures."
    task :all => :environment do
      timed { create_users  }
      timed { create_sites  }
      # timed { create_videos }
    end
    
    desc "Load User development fixtures."
    task :users => :environment do
      timed { empty_tables(Site, User)                                           }
      timed { create_users((ARGV.size > 1 ? ARGV[1].sub(/COUNT=/, '').to_i : 5)) }
    end
    
    desc "Load Site development fixtures."
    task :sites => :environment do
      timed { empty_tables(Site)                                                 }
      timed { create_sites((ARGV.size > 1 ? ARGV[1].sub(/COUNT=/, '').to_i : 5)) }
    end
    
    desc "Load Video development fixtures."
    task :videos => :environment do
      timed { empty_tables(Video)                                                  }
      timed { create_videos((ARGV.size > 1 ? ARGV[1].sub(/COUNT=/, '').to_i : 8)) }
    end
    
  end
  
end

private

def empty_tables(*tables)
  print "Deleting the content of #{tables.join(', ')}.. => "
  tables.map(&:delete_all)
  print "#{tables.join(', ')} empty!\n"
end

def create_admins
  disable_perform_deliveries do
    print "Creating admins => "
    BASE_USERS.each do |admin_infos|
      admin = Admin.create(:full_name => admin_infos[0], :email => admin_infos[1], :password => "123456")
      admin.confirmed_at = Time.now
      admin.save!
      print "Admin #{admin_infos[1]}:123456 created!\n"
    end
  end
end

def create_users(count = 5)
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
      user.save!
    end
    print "#{count} random users created!\n"
  end
end

def create_sites(count = 5)
  delete_all_files_in_public('uploads/licenses')
  delete_all_files_in_public('uploads/loaders')
  create_users if User.all.empty?
  
  User.all.each do |user|
    count.times do |i|
      site            = user.sites.build
      site.hostname   = "#{rand > 0.5 ? '' : %w[www. blog. my. git. sv. ji. geek.].rand}#{Faker::Internet.domain_name}"
      site.created_at = rand(1500).days.ago
      site.flash_hits_cache  = rand(10000)
      site.player_hits_cache     = rand(500) + site.flash_hits_cache
      site.loader_hits_cache = rand(100000) + site.player_hits_cache
      site.save!
      site.activate
    end
  end
  print "#{count} random sites created for each user!\n"
end

def create_videos(count = 8)
  delete_all_files_in_public('uploads/videos')
  create_users if User.all.empty?
  
  User.all.each do |user|
    count.times do |i|
      original = user.videos.build(:file => File.open("#{Rails.root}/spec/fixtures/railscast_intro.mov"), :width => 600, :height => 255, :size => rand(15000), :codec => 'h264', :extname => '.mp4', :duration => rand(7200), :state => 'active')
      original.created_at = rand(1500).days.ago
      original.panda_id   = "#{user.id*(i+1)}"
      original.name       = Faker::Name.name
      original.save!
      FORMATS.each_with_index do |format_name, index|
        format            = original.formats.build(:name => format_name, :width => 600, :height => 255, :size => rand(15000), :codec => 'h264', :extname => '.mp4', :duration => rand(7200))
        format.created_at = original.created_at + rand(2).days
        f                 = CarrierWave::SanitizedFile.new("#{Rails.root}/spec/fixtures/railscast_intro.mov")
        copied_file       = f.copy_to("#{Rails.root}/spec/fixtures/#{format_name.parameterize}.mov")
        format.file       = copied_file
        format.panda_id   = "#{rand(10000)*(index+1)}"
        format.save!
        format.activate
        copied_file.delete
      end
    end
  end
  print "#{User.all.size * count * (FORMATS.size + 1)} videos (1 original and #{FORMATS.size} formats per user) created!\n"
end

def timed(&block)
  if block_given?
    start_time = Time.now
    yield
    print "\tDone in #{Time.now - start_time}s!\n\n"
  else
    print "\n\nYou should pass a block to this method!\n\n"
  end
end

def delete_all_files_in_public(path)
  if path.gsub('.', '') =~ /\w+/ # don't remove all files and directories in /public ! ;)
    print "Deleting all files and directories in /public/#{path}\n"
    timed do
      Dir["#{Rails.public_path}/#{path}/**/*"].each do |filename|
        File.delete(filename) if File.file? filename
      end
      Dir["#{Rails.public_path}/#{path}/**/*"].each do |filename|
        Dir.delete(filename) if File.directory? filename
      end
    end
  end
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
    print "\n\nYou should pass a block to this method!\n\n"
  end
end