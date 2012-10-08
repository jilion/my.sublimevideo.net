# TODO
# - include component relation with good version depending on the site.player_mode (stabe, beta, alpha) & app component

require 'tempfile'
require_dependency 'cdn/file'

module Service
  Loader = Struct.new(:site, :mode, :options, :file, :cdn_file) do
    self::MODES = %w[stable beta alpha]
    delegate :token, :player_mode, to: :site
    delegate :upload!, :delete!, :present?, to: :cdn_file

    def self.update_all_modes!(site_id, options = {})
      site = Site.find(site_id)
      modes_needed = site_loader_modes(site)
      changed = []
      self::MODES.each do |mode|
        if modes_needed.include?(mode)
          changed << new(site, mode, options).upload!
        else
          new(site, mode, options).delete!
        end
      end
      site.touch(:loaders_updated_at) if changed.any? && options[:touch] != false
    end

    def initialize(*args)
      super
      self.file = generate_file
      self.cdn_file = CDN::File.new(
        file,
        destinations,
        s3_options,
        options
      )
    end

    def components_path
      [] # TODO Thibaud
    end

  private

    def self.site_loader_modes(site)
      if site.state == 'active'
        case site.player_mode
        when 'stable'; %w[stable]
        when 'beta'; %w[stable beta]
        when 'alpha', 'dev'; %w[stable beta alpha]
        end
      else
        []
      end
    end

    def generate_file
      template_path = Rails.root.join("app/templates/app/#{template_file}")
      template = ERB.new(File.new(template_path).read)
      file = Tempfile.new("l-#{site.token}.js", "#{Rails.root}/tmp")
      file.print template.result(binding)
      file.flush
      file
    end

    def template_file
      if mode == 'stable'
        "loader-old.js.erb"
      else
        "loader.js.erb"
      end
    end

    def destinations
      if mode == 'stable'
        [{
          bucket: S3.buckets['sublimevideo'],
          path: "js/#{site.token}.js"
        },{
          bucket: S3.buckets['loaders'],
          path: "loaders/#{site.token}.js"
        }]
      else
        [{
          bucket: S3.buckets['sublimevideo'],
          path: "js/#{site.token}-#{mode}.js"
        }]
      end
    end

    def s3_options
      {
        'Cache-Control' => 'max-age=120, public', # 2 minutes
        'Content-Type'  => 'text/javascript',
        'x-amz-acl'     => 'public-read'
      }
    end

  end
end
