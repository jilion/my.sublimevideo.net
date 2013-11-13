require 'tempfile'
require 'solve'

# models
require 'app'
require 'stage'

# wrappers
require 'cdn_file'
require 'campfire_wrapper'
require 's3_wrapper'

# services
require 'app/component_version_dependencies_solver'

class LoaderGenerator
  IMPORTANT_SITE_TOKENS = %w[utcf6unc]

  attr_reader :site, :stage, :options

  delegate :token, to: :site

  def initialize(site, stage, options = {})
    @site, @stage, @options = site, stage, options
  end

  def self.update_stage!(site_id, stage, options = {})
    site = Site.find(site_id)
    generator = new(site, stage, options)

    if site.active? && stage.in?(Stage.stages_equal_or_more_stable_than(site.accessible_stage))
      generator.upload!
    elsif options[:deletable]
      generator.delete!
    end
  end

  def self.update_all_stages!(site_id, options = {})
    Stage.stages.each do |stage|
      update_stage!(site_id, stage, options)
    end
  end

  def self.update_all_dependant_sites(component_id, stage)
    component = App::Component.find(component_id)
    component.clear_caches # force cache clearance

    delay(queue: 'my').update_important_sites

    sites = _sites_non_important(component: component, stage: stage)
    CampfireWrapper.delay(queue: 'my').post("Start updating all loaders for #{sites.count} sites with the #{stage} stage accessible")
    sites.find_each do |site|
      delay(queue: 'my-loader').update_all_stages!(site.id)
    end
    notify_when_loader_queue_is_empty
  end

  def self.update_important_sites
    sites = Site.where(token: (::SiteToken.tokens + IMPORTANT_SITE_TOKENS))
    CampfireWrapper.delay(queue: 'my').post("Start updating all loaders for #{sites.count} *important* sites")
    sites.pluck(:id).each do |site_id|
      delay(queue: 'my').update_all_stages!(site_id)
    end
  end

  def self.notify_when_loader_queue_is_empty
    if Sidekiq::Queue.new('my-loader').size.zero?
      CampfireWrapper.delay(queue: 'my').post('All loaders updated!')
    else
      delay(queue: 'my-low', at: 1.minute.from_now.change(min: 0).to_i).notify_when_loader_queue_is_empty
    end
  end

  def host
    case Rails.env
    when 'staging'
      '//cdn.sublimevideo-staging.net'
    else
      '//cdn.sublimevideo.net'
    end
  end

  def app_component_version
    _components_dependencies[App::Component.app_component.token]
  end

  def components_versions
    _components_dependencies.select { |token, version| token != App::Component.app_component.token }
  end

  def template_file
    "loader-#{stage}.js.erb"
  end

  def cdn_file
    @cdn_file ||= CDNFile.new(_file, _path, _s3_headers)
  end

  def upload!
    cdn_file.upload!
    _increment_librato('update')
  end

  def delete!
    cdn_file.delete!
    _increment_librato('delete')
  end

  private

  def self._sites_non_important(args = {})
    initial_scope = args[:component].app_component? ? Site : args[:component].sites

    initial_scope.all.where.not(token: (SiteToken.tokens + IMPORTANT_SITE_TOKENS)) # not important sites
    .select(:id).active.where(accessible_stage: Stage.stages_equal_or_less_stable_than(args[:stage]))
    .order(last_30_days_admin_starts: :desc, created_at: :desc)
  end

  def _file
    @_file ||= _generate_file
  end

  def _increment_librato(action)
    Librato.increment "loader.#{action}", source: stage
  end

  def _generate_file
    template_path = Rails.root.join('app', 'templates', template_file)
    template = ERB.new(File.new(template_path).read)
    file = Tempfile.new(["l-#{token}", '.js'], Rails.root.join('tmp'))
    file.print template.result(binding)
    file.flush
    file
  end

  def _components_dependencies
    @_components_dependencies ||= App::ComponentVersionDependenciesSolver.components_dependencies(site, stage)
  end

  def _path
    case stage
    when 'stable'
      "js/#{token}.js"
    else
      "js/#{token}-#{stage}.js"
    end
  end

  def _s3_headers
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
