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
      timed { empty_tables("delayed_jobs", Invoice, Log, VideoUsage, VideoEncoding, Video, VideoProfileVersion, VideoProfile, SiteUsage, Site, User, Admin) }
    end
    
    desc "Load all development fixtures."
    task :all => :environment do
      delete_all_files_in_public('uploads/tmp')
      timed { create_admins }
      timed { create_users  }
      timed { create_sites  }
      timed { create_video_profiles }
      timed { create_videos }
    end
    
    desc "Load User development fixtures."
    task :users => :environment do
      timed { empty_tables(Site, User)                                           }
      timed { create_users((ARGV.size > 1 ? ARGV[1].sub(/COUNT=/, '').to_i : 5)) }
    end
    
    desc "Load Admin development fixtures."
    task :admins => :environment do
      timed { empty_tables(Admin) }
      timed { create_admins       }
    end
    
    desc "Load Site development fixtures."
    task :sites => :environment do
      timed { empty_tables(Site)                                                 }
      timed { create_sites((ARGV.size > 1 ? ARGV[1].sub(/COUNT=/, '').to_i : 5)) }
    end
    
    desc "Load Video Profile development fixtures."
    task :video_profiles => :environment do
      timed { empty_tables(VideoProfileVersion, VideoProfile) }
      timed { create_video_profiles }
    end
    
    desc "Load Video development fixtures."
    task :videos => :environment do
      timed { empty_tables(VideoEncoding, Video, VideoProfileVersion, VideoProfile) }
      timed { create_videos((ARGV.size > 1 ? ARGV[1].sub(/COUNT=/, '').to_i : 1))   }
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
  tables.each do |table|
    if table.is_a?(Class)
      table.delete_all
    else
      Video.connection.delete("DELETE FROM #{table} WHERE 1=1")
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
      site.flash_hits_cache  = rand(1000)
      site.player_hits_cache = rand(500) + site.flash_hits_cache
      site.loader_hits_cache = rand(10000) + site.player_hits_cache
      site.save!
      site.activate
    end
  end
  print "#{count} random sites created for each user!\n"
end

def create_video_profiles
  active_video_profile         = VideoProfile.new(:title => "iPhone 720p", :thumbnailable => true)
  active_video_profile.name = "_iphone_720p"
  active_video_profile.extname = "mp4"
  active_video_profile.save(:validate => false)
  
  active_video_profile_version = active_video_profile.versions.build(:width => 640, :height => 480, :command => "HandBrakeCLI -i $input_file$ -o $output_file$  -e x264 -q 0.589999973773956 -a 1 -E faac -B 128 -R 48 -6 dpl2 -f mp4 -X 480 -m -x level=30:cabac=0:ref=2:mixed-refs:analyse=all:me=umh:no-fast-pskip=1")
  active_video_profile_version.panda_profile_id = 'ef5c5e7d10b7216c703f87ab34eafa98'
  active_video_profile_version.state = 'active'
  active_video_profile_version.save(:validate => false)
  print "One video profile with one version created!\n"
end

def create_videos(count = 1)
  delete_all_files_in_public('uploads/videos')
  create_users if User.all.empty?
  
  create_video_profiles if VideoProfile.all.empty?
  VideoProfileVersion.last.activate unless VideoProfileVersion.last.active?
  
  panda_video_id = 'df69f0331c4e4b619efadb95dea9f6a2' # Transcoder.post(:video, { :file => File.open("#{Rails.root}/spec/fixtures/railscast_intro.mov"), :profiles => 'none' })[:id]
  
  User.all.each do |user|
    count.times do |i|
      video = user.videos.build
      video.panda_video_id = panda_video_id
      video.created_at     = rand(1500).days.ago
      video.save!
      video.pandize
    end
  end
  print "#{User.all.size * count * (VideoProfileVersion.active.all.size + 1)} videos (1 video and #{VideoProfileVersion.active.all.size} encodings per user) created!\n"
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
      Dir.glob("#{Rails.public_path}/#{path}/**/*", File::FNM_DOTMATCH).each do |filename|
        File.delete(filename) if File.file?(filename) && ['.', '..'].exclude?(File.basename(filename))
      end
      Dir.glob("#{Rails.public_path}/#{path}/**/*", File::FNM_DOTMATCH).each do |filename|
        Dir.delete(filename) if File.directory?(filename) && ['.', '..'].exclude?(File.basename(filename))
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