class StatsExport
  include Mongoid::Document
  include Mongoid::Timestamps

  field :_id, default: -> { unique_token }
  field :st, as: :site_token
  field :from, type: DateTime
  field :to,   type: DateTime

  index site_token: 1

  mount_uploader :file, StatsExportUploader

  validates :site_token, :from, :to, :file, presence: true

  def site
    Site.where(token: site_token).first
  end

  def site_hostname
    site.hostname
  end

private

  def unique_token
    begin
      unique_token = generate_token
    end while self.class.where('_id' => unique_token).exists?
    unique_token
  end

  def generate_token
    chars = (Array('a'..'z') + Array('0'..'9')).to_a
    Array.new(8) { chars[rand(chars.size)] }.join
  end

end
