# TODO
# - per site
# - include component relation with good version depending on the site.player_mode (stabe, beta, alpha) & app component

require 'tempfile'
require_dependency 'cdn'

class Player::Loader < Struct.new(:site, :mode, :file)
  delegate :token, :player_mode, to: :site

  def self.update!(site_id, mode)
    site = Site.find(site_id)
    loader = new(site, mode)
    loader.upload!
  end

  def self.delete!(site_id)
    site = Site.find(site_id)
    loader = new(site, mode)
    loader.delete!
  end

  def initialize(*args)
    super
    generate_file
  end

  def upload!
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
  end

  def delete!
    mode_config[:destinations].each do |destination|
      S3.fog_connection.delete_object(
        destination[:bucket],
        destination[:path]
      )
    end
    purge_cdn
  end

  def components_path
    [] # TODO Thibaud
  end

private

  def generate_file
    template_path = Rails.root.join("app/templates/player/#{mode_config[:template]}")
    template = ERB.new(File.new(template_path).read)
    self.file = Tempfile.new("l-#{site.token}.js", "#{Rails.root}/tmp")
    self.file.print template.result(binding)
    self.file.flush
  end

  def s3_put_object(bucket, path, data)
    S3.fog_connection.put_object(
      bucket,
      path,
      data,
      {
        'Cache-Control' => 'max-age=120, public', # 2 minutes
        'Content-Type'  => 'text/javascript',
        'x-amz-acl'     => 'public-read'
      }
    )
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
