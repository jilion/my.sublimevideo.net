require 'tempfile'
require_dependency 'cdn'

class Player::Settings < Struct.new(:site, :file)

  TEMPLATE_PATH = Rails.root.join("app/templates/player/settings.js.erb")

  def self.update!(site)
    settings = new(site)
    settings.upload!
  end

  def initialize(*args)
    super
    generate_file
  end

  def upload!
    File.open(file) do |f|
      S3.fog_connection.put_object(
        S3.buckets['sublimevideo'],
        filepath,
        f.read,
        {
          'Cache-Control' => 'max-age=120, public', # 2 minutes
          'Content-Type'  => 'text/javascript',
          'x-amz-acl'     => 'public-read'
        }
      )
    end
    CDN.purge(filepath)
  end

  def remove!
    S3.fog_connection.delete_object(
      S3.buckets['sublimevideo'],
      filepath
    )
    CDN.purge(filepath)
  end

  def filepath
    "s/#{site.token}.js"
  end

  def hash
    hash = { h: [site.hostname] }
    hash[:h] += site.extra_hostnames.split(/,\s*/) if site.extra_hostnames?
    hash[:d]  = site.dev_hostnames.split(/,\s*/) if site.dev_hostnames?
    hash[:w]  = site.wildcard if site.wildcard?
    hash[:p]  = site.path if site.path?
    hash[:b]  = site.badged
    hash[:s]  = true unless site.in_free_plan? # SSL
    hash[:r]  = true if site.plan_stats_retention_days != 0 # Realtime Stats
    hash
  end

  def json
    hash.to_s.gsub(/:|\s/, '').gsub(/\=\>/, ':')
  end

private

  def generate_file
    template = ERB.new(File.new(TEMPLATE_PATH).read)
    self.file = Tempfile.new("s-#{site.token}.js", "#{Rails.root}/tmp")
    self.file.print template.result(binding)
    self.file.flush
  end

end
