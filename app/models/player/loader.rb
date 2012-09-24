# TODO
# - include component relation with good version depending on the site.player_mode (stabe, beta, alpha) & app component

require 'tempfile'
require 'digest/md5'
require_dependency 'cdn'

class Player::Loader < Struct.new(:site, :mode, :file)
  MODES = %w[stable beta alpha]
  delegate :token, :player_mode, to: :site

  def self.update_all_modes!(site_id)
    site = Site.find(site_id)
    modes_needed = site_loader_modes(site)
    changed = []
    MODES.each do |mode|
      if modes_needed.include?(mode)
        changed << new(site, mode).upload!
      else
        new(site, mode).delete!
      end
    end
    site.touch(:loaders_updated_at) if changed.any?
  end

  def initialize(*args)
    super
    generate_file
  end

  def upload!
    if changed?
      File.open(file) do |f|
        data = f.read
        mode_config[:destinations].each do |destination|
          s3_put_object(
            destination[:bucket],
            destination[:path],
            data
          )
        end
      end
      purge_cdn
      true
    end
  end

  def delete!
    if present?
      mode_config[:destinations].each do |destination|
        S3.fog_connection.delete_object(
          destination[:bucket],
          destination[:path]
        )
      end
      purge_cdn
      true
    end
  end

  def components_path
    [] # TODO Thibaud
  end

  # loader already present on S3?
  def present?
    mode_config[:destinations].all? do |destination|
      s3_headers(
        destination[:bucket],
        destination[:path]
      ).present?
    end
  end

  # loader different that the one already present on S3?
  def changed?
    md5 != uploaded_md5
  end

private

  def self.site_loader_modes(site)
    if site.state == 'active'
      case site.player_mode
      when 'stable'; %w[stable]
      when 'beta'; %w[stable beta]
      when 'alpha'; %w[stable beta alpha]
      end
    else
      []
    end
  end

  def generate_file
    template_path = Rails.root.join("app/templates/player/#{mode_config[:template]}")
    template = ERB.new(File.new(template_path).read)
    self.file = Tempfile.new("l-#{site.token}.js", "#{Rails.root}/tmp")
    self.file.print template.result(binding)
    self.file.flush
  end

  def md5
    File.open(file) { |f| Digest::MD5.base64digest(f.read) }
  end

  def uploaded_md5
    destination = mode_config[:destinations].first
    s3_headers(
      destination[:bucket],
      destination[:path]
    )['Content-MD5']
  end

  def s3_put_object(bucket, path, data)
    S3.fog_connection.put_object(
      bucket,
      path,
      data,
      {
        'Cache-Control' => 'max-age=120, public', # 2 minutes
        'Content-Type'  => 'text/javascript',
        'Content-MD5'   => md5,
        'x-amz-acl'     => 'public-read'
      }
    )
  end

  def s3_headers(bucket, path)
    S3.fog_connection.head_object(
      bucket,
      path
    ).headers
  rescue Excon::Errors::NotFound
    {}
  end

  def purge_cdn
    CDN.purge("/#{first_destination_path}")
  end

  def first_destination_path
    mode_config[:destinations].first[:path]
  end

  def mode_config
    # Handle old loader
    if mode == 'stable'
      {
        template: "loader-old.js.erb",
        destinations: [{
          bucket: S3.buckets['sublimevideo'],
          path: "js/#{site.token}.js"
        },{
          bucket: S3.buckets['loaders'],
          path: "loaders/#{site.token}.js"
        }]
      }
    else
      {
        template: "loader.js.erb",
        destinations: [{
          bucket: S3.buckets['sublimevideo'],
          path: "js/#{site.token}-#{mode}.js"
        }]
      }
    end
  end

end
