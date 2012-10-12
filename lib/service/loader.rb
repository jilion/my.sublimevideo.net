require 'tempfile'
require_dependency 'cdn/file'

module Service
  Loader = Struct.new(:site, :stage, :options, :file, :cdn_file) do
    delegate :token, :accessible_stage, :player_mode, to: :site
    delegate :upload!, :delete!, :present?, to: :cdn_file

    def self.update_all_stages!(site_id, options = {})
      site = ::Site.find(site_id)
      changed = []
      Stage::STAGES.each do |stage|
        if site.active? && stage >= site.accessible_stage
          changed << new(site, stage, options).upload!
        else
          changed << new(site, stage, options).delete!
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

    def host
      "//cdn.sublimevideo.net"
    end

    def app_component_version
      components_dependencies[App::Component.app_component.token]
    end

    def components_versions
      components_dependencies.select { |token, version| token != App::Component.app_component.token }
    end

    def components_dependencies
      @components_dependencies ||=
        App::ComponentVersionDependenciesSolver.components_dependencies(site, stage)
    end

  private

    def generate_file
      template_path = Rails.root.join("app/templates/app/#{template_file}")
      template = ERB.new(File.new(template_path).read)
      file = Tempfile.new("l-#{site.token}.js", "#{Rails.root}/tmp")
      file.print template.result(binding)
      file.flush
      file
    end

    def template_file
      if stage == 'stable'
        "loader-old.js.erb"
      else
        "loader.js.erb"
      end
    end

    def destinations
      if stage == 'stable'
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
          path: "js/#{site.token}-#{stage}.js"
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
