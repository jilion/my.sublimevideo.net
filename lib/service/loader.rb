require 'tempfile'
require_dependency 'cdn/file'
require_dependency 'app/component_version_dependencies_solver'

module Service
  Loader = Struct.new(:site, :stage, :options, :file, :cdn_file) do
    delegate :token, :accessible_stage, :player_mode, to: :site
    delegate :upload!, :delete!, :present?, to: :cdn_file

    def self.update_all_stages!(site_id, options = {})
      site = ::Site.find(site_id)
      Stage.stages.each do |stage|
        if site.active? && stage >= site.accessible_stage
          new(site, stage, options).upload!
          Librato.increment 'loader.update', source: stage
        else
          new(site, stage, options).delete!
          Librato.increment 'loader.delete', source: stage
        end
      end
    end

    def self.update_all_dependant_sites(component_id, stage)
      delay(queue: 'high').update_important_sites

      component = ::App::Component.find(component_id)
      if component.app_component?
        sites = ::Site.scoped
      else
        sites = component.sites.scoped
      end
      sites = sites.where{ token << ::SiteToken.tokens } # not important sites
      sites = sites.select(:id).active.where(accessible_stage: Stage.stages_with_access_to(stage))
      sites.order{ last_30_days_main_video_views.desc }.order{ created_at.desc }.find_each do |site|
        delay(queue: 'loader').update_all_stages!(site.id)
      end
    end

    def self.update_important_sites
      ::Site.select(:id).where{ token >> ::SiteToken.tokens }.each do |site|
        delay(queue: 'high').update_all_stages!(site.id)
      end
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
      if Rails.env == 'staging'
        "//cdn.sublimevideo-staging.net"
      else
        "//cdn.sublimevideo.net"
      end
    end

    def app_component_version
      components_dependencies[::App::Component.app_component.token]
    end

    def components_versions
      components_dependencies.select { |token, version| token != ::App::Component.app_component.token }
    end

  private

    def generate_file
      template_path = Rails.root.join('app', 'templates', 'app', template_file)
      template = ERB.new(File.new(template_path).read)
      file = Tempfile.new("l-#{site.token}.js", Rails.root.join('tmp'))
      file.print template.result(binding)
      file.flush
      file
    end

    def components_dependencies
      @components_dependencies ||= ::App::ComponentVersionDependenciesSolver.components_dependencies(site, stage)
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
        'Cache-Control' => stage == 'alpha' ? 'no-cache' : 's-maxage=300, max-age=120, public', # 5 minutes / 2 minutes
        'Content-Type'  => 'text/javascript',
        'x-amz-acl'     => 'public-read'
      }
    end

  end
end
