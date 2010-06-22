# coding: utf-8
require 'state_machine'
require 'ffaker'

BASE_USERS = [["Mehdi Aminian", "mehdi@jilion.com"], ["Zeno Crivelli", "zeno@jilion.com"], ["Thibaud Guillaume-Gentil", "thibaud@jilion.com"], ["Octave Zangs", "octave@jilion.com"], ["Rémy Coutable", "remy@jilion.com"]]
PROFILES    = %w[Desktop 3G WiFi Ogg]

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
      timed { empty_tables(Video, VideoProfileVersion, VideoProfile)              }
      timed { create_videos((ARGV.size > 1 ? ARGV[1].sub(/COUNT=/, '').to_i : 1)) }
    end
    
  end
  
end

namespace :sm do
  
  desc "Draw the States Diagrams for every model having State Machine"
  task :draw => :environment do
    %x(rake state_machine:draw CLASS=Invoice,Log,Site,User,Video,VideoEncoding,VideoProfileVersion TARGET=doc/state_diagrams FORMAT=jpg ORIENTATION=landscape)
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

def create_users(count = 1)
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

def create_sites(count = 1)
  delete_all_files_in_public('uploads/licenses')
  delete_all_files_in_public('uploads/loaders')
  create_users if User.all.empty?
  
  User.all.each do |user|
    count.times do |i|
      site            = user.sites.build
      site.hostname   = "#{rand > 0.5 ? '' : %w[www. blog. my. git. sv. ji. geek.].sample}#{Faker::Internet.domain_name}"
      site.created_at = rand(1500).days.ago
      site.flash_hits_cache  = rand(10000)
      site.player_hits_cache = rand(500) + site.flash_hits_cache
      site.loader_hits_cache = rand(100000) + site.player_hits_cache
      site.save!
      site.activate
    end
  end
  print "#{count} random sites created for each user!\n"
end

def create_videos(count = 1)
  delete_all_files_in_public('uploads/videos')
  create_users if User.all.empty?
  
  active_video_profile         = VideoProfile.create(:title => "iPhone 720p", :name => "_iphone_720p", :extname => ".mp4", :thumbnailable => true)
  active_video_profile_version = active_video_profile.versions.build(:width => 640, :height => 480, :command => "Handbrake CLI")
  active_video_profile_version.pandize
  active_video_profile_version.activate
  
  @panda_video_id = Transcoder.post(:video, { :file => File.open("#{Rails.root}/spec/fixtures/railscast_intro.mov"), :profiles => 'none' })[:id]
  
  User.all.each do |user|
    count.times do |i|
      # video = user.videos.build(:file => File.open("#{Rails.root}/spec/fixtures/railscast_intro.mov"), :width => 600, :height => 255, :size => rand(15000), :codec => 'h264', :extname => '.mp4', :duration => rand(7200), :state => 'active')
      video = user.videos.build
      video.panda_video_id = @panda_video_id
      video.created_at     = rand(1500).days.ago
      video.save!
      video.pandize
      Delayed::Worker.new(:quiet => true).work_off
      
      video.encodings.each do |video_encoding|
        video_encoding.created_at = video.created_at + rand(2).days
        video_encoding.activate
      end
      Delayed::Worker.new(:quiet => true).work_off
      
      # VideoProfile.active.each do |video_profile|
      #   encoding = Factory(:video_encoding, :profile_version => Factory(:video_profile_version, :panda_profile_id => '73f93e74e866d86624a8718d21d06e4e'))
      #   
      #   encoding            = video.encodings.build(:width => 600, :height => 255, :size => rand(15000), :codec => 'h264', :extname => '.mp4', :duration => rand(7200))
      #   encoding.created_at = video.created_at + rand(2).days
      #   f                 = CarrierWave::SanitizedFile.new("#{Rails.root}/spec/fixtures/railscast_intro.mov")
      #   copied_file       = f.copy_to("#{Rails.root}/spec/fixtures/#{profile_name.parameterize}.mov")
      #   encoding.file       = copied_file
      #   encoding.panda_id   = "#{rand(10000)*(index+1)}"
      #   encoding.save!
      #   encoding.activate
      #   copied_file.delete
      # end
    end
  end
  print "#{User.all.size * count * (VideoProfile.active.size + 1)} videos (1 video and #{VideoProfile.active.size} encodings per user) created!\n"
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