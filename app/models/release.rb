class Release < ActiveRecord::Base

  attr_accessible :zip
  mount_uploader :zip, ReleaseUploader
  uniquify :token, :length => 10, :chars => Array('A'..'Z') + Array('0'..'9')

  # ===============
  # = Validations =
  # ===============

  validates :zip, :presence => true

  # =============
  # = Callbacks =
  # =============

  before_validation :set_date
  after_create :flag

  # =================
  # = State Machine =
  # =================

  state_machine :initial => :archived do
    event(:flag)    { transition :archived => :dev, :dev => :beta, :beta => :stable }
    event(:archive) { transition [:dev, :beta, :stable] => :archived }

    after_transition :to => :dev, :do => :overwrite_dev_with_zip_content
    after_transition :to => [:beta, :stable], :do => :copy_content_to_next_state
    after_transition :to => [:dev, :beta, :stable], :do => :archive_old_release
    after_transition :on => :flag, :do => :purge_old_release_dir
  end

  # =================
  # = Class Methods =
  # =================

  def self.stable_release
    where(:state => "stable").first
  end

  def self.beta_release
     releases = where{ (state == "beta") | (state == "stable") }.all
     releases.detect { |r| r.state == "beta" } || releases.detect { |r| r.state == "stable" }
  end

  def self.dev_release
     releases = where{ (state == "dev") | (state == "beta") | (state == "stable") }
     releases.detect { |r| r.state == "dev" } || releases.detect { |r| r.state == "beta" } || releases.detect { |r| r.state == "stable" }
  end

  # ====================
  # = Instance Methods =
  # ====================

  def zipfile
    # Download file from S3 to read the zip content
    # please don't forget to call delete_zipfile
    unless @zipfile
      @local_zip_file = File.new(Rails.root.join("tmp/#{read_attribute(:zip)}"), 'w', :encoding => 'ASCII-8BIT')
      @local_zip_file.write(zip.read)
      @local_zip_file.flush
      @zipfile = Zip::ZipFile.open(@local_zip_file.path)
    end
    @zipfile
  end

  def files_in_zip
    @files_in_zip ||= zipfile.select { |file| file.file? && file.name !~ /__MACOSX|\.DS_Store/ }
    if block_given?
      @files_in_zip.each { |e| yield e }
      delete_zipfile # clean tmp file
    else
      @files_in_zip
    end
  end

  def delete_zipfile
    File.delete(@local_zip_file.path)
    @zipfile = nil
    @files_in_zip = nil
  end

private

  # before_validation
  def set_date
    self.date ||= Time.now.utc.strftime("%Y-%m-%d-%H-%M-%S")
  end

  # after_transition to dev
  def overwrite_dev_with_zip_content
    S3.player_bucket.delete_folder('dev')
    files_in_zip do |file|
      S3.player_bucket.put("dev/#{file.name}", zipfile.read(file), {}, "public-read",
        'content-type' => FileHeader.content_type(file.to_s),
        'content-encoding' => FileHeader.content_encoding(file.to_s)
      )
    end
  end

  # after_transition to beta, stable
  def copy_content_to_next_state
    old_keys_names = S3.keys_names(S3.player_bucket, 'prefix' => state, :remove_prefix => true)
    new_keys_names = S3.keys_names(S3.player_bucket, 'prefix' => state_was, :remove_prefix => true)
    # copy new keys to next state level
    new_keys_names.each do |name|
      from = state_was + name
      to   = state + name
      S3.client.interface.copy(S3.player_bucket.name, from, S3.player_bucket.name, to, :copy, 'x-amz-acl' => 'public-read')
    end
    # Remove no more used keys
    (old_keys_names - new_keys_names).each do |name|
      S3.client.interface.delete(S3.player_bucket.name, state + name)
    end
  end

  # after_transition to dev, beta, stable
  def archive_old_release
    old_release = Release.where(:state => state, :id.not_eq => self.id).first
    # old_release can be nil if there was no old release with that state
    old_release.try(:archive)
  end

  # after_transition on flag
  def purge_old_release_dir
    return unless Rails.env.production? || Rails.env.test?
    case state
    when 'dev', 'beta'
      VoxcastCDN.purge_dir "/p/#{state}"
    when 'stable'
      VoxcastCDN.purge_dir "/p"
    end
  end

end
# == Schema Information
#
# Table name: releases
#
#  id         :integer         not null, primary key
#  token      :string(255)
#  date       :string(255)
#  zip        :string(255)
#  state      :string(255)
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_releases_on_state  (state)
#
