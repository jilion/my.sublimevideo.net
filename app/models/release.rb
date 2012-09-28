require_dependency 'file_header'
require_dependency 's3'

class Release < ActiveRecord::Base

  attr_accessible :zip
  mount_uploader :zip, ReleaseUploader
  uniquify :token, length: 10, chars: Array('A'..'Z') + Array('0'..'9')

  # ===============
  # = Validations =
  # ===============

  validates :zip, presence: true

  # =============
  # = Callbacks =
  # =============

  before_validation :set_date
  after_create :flag

  # =================
  # = State Machine =
  # =================

  state_machine initial: :archived do
    event(:flag)    { transition archived: :dev, dev: :beta, beta: :stable }
    event(:archive) { transition [:dev, :beta, :stable] => :archived }

    after_transition to: :dev, do: :overwrite_dev_with_zip_content
    after_transition to: [:beta, :stable], do: :copy_content_to_next_state
    after_transition to: [:dev, :beta, :stable], do: :archive_old_release
    after_transition on: :flag, do: :purge_old_release_dir
  end

  # =================
  # = Class Methods =
  # =================

  def self.stable_release
    where(state: "stable").first
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
    @zipfile ||= begin
      @local_zip_file = File.new(Rails.root.join("tmp/#{read_attribute(:zip)}"), 'w', encoding: 'ASCII-8BIT')

      # Issue 1: We're using read_attribute(:zip) here because zip.filename return the actual filename only on creation
      # On update, zip.filename is blank!? In this case read_attribute(:zip) is always right...
      # Issue 2: There's an issue with CarrierWave's "zip.read" method, use AWS directly instead...
      # Note: no problem when using :file as storage
      @local_zip_file.write(Rails.env.test? ? zip.read : S3.player_bucket.get("#{zip.store_dir}/#{read_attribute(:zip)}"))
      @local_zip_file.flush
      Zip::ZipFile.open(@local_zip_file.path)
    end
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
    S3.sublimevideo_bucket.delete_folder('p/dev')
    files_in_zip do |file|
      S3.player_bucket.put("dev/#{file.name}", zipfile.read(file), {}, 'public-read',
        'content-type' => FileHeader.content_type(file.to_s),
        'content-encoding' => FileHeader.content_encoding(file.to_s)
      )
      S3.sublimevideo_bucket.put("p/dev/#{file.name}", zipfile.read(file), {}, 'public-read',
        'content-type' => FileHeader.content_type(file.to_s),
        'content-encoding' => FileHeader.content_encoding(file.to_s)
      )
    end
  end

  # after_transition to beta, stable
  def copy_content_to_next_state
    old_keys_names = S3.keys_names(S3.player_bucket, 'prefix' => state, remove_prefix: true)
    new_keys_names = S3.keys_names(S3.player_bucket, 'prefix' => state_was, remove_prefix: true)
    # copy new keys to next state level
    new_keys_names.each do |name|
      from = state_was + name
      to   = state + name
      S3.client.interface.copy(S3.player_bucket.name, from, S3.player_bucket.name, to, :copy, 'x-amz-acl' => 'public-read')
      from = sublimevideo_bucket_state(state_was) + name
      to   = sublimevideo_bucket_state(state) + name
      S3.client.interface.copy(S3.sublimevideo_bucket.name, from, S3.sublimevideo_bucket.name, to, :copy, 'x-amz-acl' => 'public-read')
    end
    # Remove no more used keys
    (old_keys_names - new_keys_names).each do |name|
      S3.player_bucket.delete_key(state + name)
      S3.sublimevideo_bucket.delete_key(sublimevideo_bucket_state(state) + name)
    end
  end

  def sublimevideo_bucket_state(state)
    case state
    when 'stable'; 'p'
    when 'beta'; 'p/beta'
    when 'dev'; 'p/dev'
    end
  end

  # after_transition to dev, beta, stable
  def archive_old_release
    old_release = Release.where{ |q| (q.state == state) & (q.id != id) }.first

    # old_release can be nil if there was no old release with that state
    old_release.try(:archive)
  end

  # after_transition on flag
  def purge_old_release_dir
    return unless Rails.env.production? || Rails.env.test?
    case state
    when 'dev', 'beta'
      CDN.purge "/p/#{state}"
      CDN.purge "/p/#{state}/*"
    when 'stable'
      CDN.purge "/p"
      CDN.purge "/p/*"
    end
  end

end

# == Schema Information
#
# Table name: releases
#
#  created_at :datetime         not null
#  date       :string(255)
#  id         :integer          not null, primary key
#  state      :string(255)
#  token      :string(255)
#  updated_at :datetime         not null
#  zip        :string(255)
#
# Indexes
#
#  index_releases_on_state  (state)
#

