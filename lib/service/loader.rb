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
        else
          new(site, stage, options).delete!
        end
      end
    end

    def self.update_all_dependant_sites(component_id, stage)
      component = ::App::Component.find(component_id)
      if component.app_component?
        sites = ::Site.scoped
        purge = false
      else
        sites = component.sites.scoped
        purge = true
      end
      sites = sites.active.where(accessible_stage: Stage.stages_with_access_to(stage))
      # Quick loader update with direct purge for site with traffic
      sites.where{ last_30_days_billable_video_views > 0 }.find_each(batch_size: 500) do |site|
        delay.update_all_stages!(site.id)
      end
      # Slower loader update with possibly no direct purge
      sites.where(last_30_days_billable_video_views: 0).find_each(batch_size: 500) do |site|
        delay(queue: 'loader').update_all_stages!(site.id, purge: purge)
      end
      delay(at: 1.minute.from_now.to_i).global_purge unless purge
    end

    def self.global_purge
      if Sidekiq::Queue.new('loader').size == 0
        CDN.delay.purge("/js")
      else
        delay(at: 1.minute.from_now.to_i).global_purge
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

    def components_dependencies
      @components_dependencies ||= ::App::ComponentVersionDependenciesSolver.components_dependencies(site, stage)
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
        'Cache-Control' => 'max-age=60, public', # 1 minutes
        'Content-Type'  => 'text/javascript',
        'x-amz-acl'     => 'public-read'
      }
    end

  end
end
