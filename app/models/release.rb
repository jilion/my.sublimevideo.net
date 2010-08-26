# == Schema Information
#
# Table name: releases
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  zip        :string(255)
#  state      :string(255)
#  created_at :datetime
#  updated_at :datetime
#

require 'zip/zip'

class Release < ActiveRecord::Base
  
  attr_accessible :zip
  
  mount_uploader :zip, ReleaseUploader
  
  # ==========
  # = Scopes =
  # ==========
  
  scope :dev,    where({ :state => "dev" } | { :state => "beta" } | { :state => "stable" })
  scope :beta,   where({ :state => "beta" } | { :state => "stable" })
  scope :stable, where(:state => "stable")
  
  # ===============
  # = Validations =
  # ===============
  
  validates :name, :presence => true, :uniqueness => true
  validates :zip, :presence => true
  
  # =============
  # = Callbacks =
  # =============
  
  before_validation :set_name
  after_create :flag
  
  # =================
  # = State Machine =
  # =================
  
  state_machine :initial => :archived do
    after_transition :to => :dev, :do => :overwrite_dev_with_zip_content
    after_transition :to => [:beta, :stable], :do => :copy_content_to_next_state
    
    event(:flag)    { transition :archived => :dev, :dev => :beta, :beta => :stable }
    event(:archive) { transition [:dev, :beta, :stable] => :archived }
  end
  
  # ====================
  # = Instance Methods =
  # ====================
  
  def zipfile
    @zipfile ||= Zip::ZipFile.open(zip.path)
  end
  
  def zip_files
    @zip_files = zipfile.select do |file|
      file.file? && !file.name.match(/__MACOSX/)
    end
  end
  
private
  
  # before_validation
  def set_name
    self.name = Time.now.utc.strftime("%Y-%m-%d-%H-%M-%S")
  end
  
  # after_transition to dev
  def overwrite_dev_with_zip_content
    S3.player_bucket.delete_folder('dev')
    zip_files.each do |file|
      S3.player_bucket.put("dev/#{file.name}", zipfile.read(file), {}, "public-read")
    end
  end
  
  # after_transition to beta, stable
  def copy_content_to_next_state
    S3.player_bucket.keys('prefix' => state_was).each do |key|
      from = key.name
      to   = key.name.gsub /^#{state_was}/, state
      puts to
      S3.player_bucket.copy_key(from, to)
      # S3.client.interface.copy(S3.panda_bucket.name, key_on_panda_bucket, S3.videos_bucket.name, key_on_videos_bucket, :copy, 'x-amz-acl' => 'public-read')
    end
    puts "copy"
  end
end