require 'tempfile'

class LoaderGenerator
  IMPORTANT_SITE_TOKENS = %w[utcf6unc]

  attr_reader :site, :stage, :options

  delegate :token, to: :site
  delegate :upload!, :delete!, to: :cdn_file

  def self.update_all_stages!(site_id, options = {})
    site = Site.find(site_id)
    Stage.stages.each do |stage|
      if site.active? && stage >= site.accessible_stage
        generator = new(site, stage, options)
        generator.upload!
        generator.increment_librato('update')
      elsif options[:deletable]
        generator = new(site, stage, options)
        generator.delete!
        generator.increment_librato('delete')
      end
    end
  end

  def self.update_all_dependant_sites(component_id, stage)
    delay(queue: 'high').update_important_sites

    sites = _sites_non_important(component: App::Component.find(component_id), stage: stage)
    CampfireWrapper.delay.post("Start updating all loaders for #{sites.count} sites with the #{stage} stage accessible")
    sites.find_each do |site|
      delay(queue: 'loader').update_all_stages!(site.id)
    end
    notify_when_loader_queue_is_empty
  end

  def self.update_important_sites
    sites = Site.select(:id).where { token >> (::SiteToken.tokens + IMPORTANT_SITE_TOKENS) }
    CampfireWrapper.delay.post("Start updating all loaders for #{sites.count} *important* sites")
    sites.each do |site|
      delay(queue: 'high').update_all_stages!(site.id)
    end
  end

  def initialize(site, stage, options = {})
    @site, @stage, @options = site, stage, options
  end

  def cdn_file
    @cdn_file ||= CDNFile.new(file, path, s3_headers)
  end

  def file
    @file ||= generate_file
  end

  def app_component_version
    components_dependencies[App::Component.app_component.token]
  end

  def components_versions
    components_dependencies.select { |token, version| token != App::Component.app_component.token }
  end

  def increment_librato(action)
    Librato.increment "loader.#{action}", source: stage
  end

  def self.notify_when_loader_queue_is_empty
    if Sidekiq::Queue.new(:loader).size.zero?
      CampfireWrapper.delay.post('All loaders updated!')
    else
      delay(at: 1.minute.from_now.change(min: 0).to_i, queue: 'low').notify_when_loader_queue_is_empty
    end
  end

  private

  def self._sites_non_important(args = {})
    initial_scope = args[:component].app_component? ? Site : args[:component].sites

    initial_scope.scoped.where { token << (SiteToken.tokens + IMPORTANT_SITE_TOKENS) } # not important sites
    .select(:id).active.where(accessible_stage: Stage.stages_with_access_to(args[:stage]))
    .order { last_30_days_main_video_views.desc }.order { created_at.desc }
  end

  def host
    if Rails.env == 'staging'
      "//cdn.sublimevideo-staging.net"
    else
      "//cdn.sublimevideo.net"
    end
  end

  def generate_file
    template_path = Rails.root.join('app', 'templates', template_file)
    template = ERB.new(File.new(template_path).read)
    file = Tempfile.new("l-#{@site.token}.js", Rails.root.join('tmp'))
    file.print template.result(binding)
    file.flush
    file
  end

  def components_dependencies
    @components_dependencies ||= App::ComponentVersionDependenciesSolver.components_dependencies(site, stage)
  end

  def template_file
    "loader-#{stage}.js.erb"
  end

  def path
    if stage == 'stable'
      "js/#{token}.js"
    else
      "js/#{token}-#{stage}.js"
    end
  end

  def s3_headers
    {
      'Cache-Control' => cache_control,
      'Content-Type'  => 'text/javascript',
      'x-amz-acl'     => 'public-read'
    }
  end

  def cache_control
    case stage
    when 'alpha'
      'no-cache'
    else
      's-maxage=300, max-age=120, public' # 5 minutes / 2 minutes
    end
  end

end
