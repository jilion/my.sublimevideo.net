require 'tempfile'

class LoaderGenerator
  extend Forwardable

  IMPORTANT_SITE_TOKENS = %w[utcf6unc]

  attr_reader :site, :stage, :options

  def_instance_delegators :site, :token
  def_instance_delegators :cdn_file, :upload!, :delete!, :present?

  def self.update_all_stages!(site_id, options = {})
    site = Site.find(site_id)
    Stage.stages.each do |stage|
      if site.active? && stage >= site.accessible_stage
        new(site, stage, options).upload!
        Librato.increment 'loader.update', source: stage
      elsif options[:deletable]
        new(site, stage, options).delete!
        Librato.increment 'loader.delete', source: stage
      end
    end
  end

  def self.update_all_dependant_sites(component_id, stage)
    delay(queue: 'high').update_important_sites

    component = App::Component.find(component_id)
    if component.app_component?
      sites = Site.scoped
    else
      sites = component.sites.scoped
    end
    sites = sites.where { token << (SiteToken.tokens + IMPORTANT_SITE_TOKENS) } # not important sites
    sites = sites.select(:id).active.where(accessible_stage: Stage.stages_with_access_to(stage))
    sites.order { last_30_days_main_video_views.desc }.order { created_at.desc }.find_each do |site|
      delay(queue: 'loader').update_all_stages!(site.id)
    end
  end

  def self.update_important_sites
    Site.select(:id).where { token >> (::SiteToken.tokens + IMPORTANT_SITE_TOKENS) }.each do |site|
      delay(queue: 'high').update_all_stages!(site.id)
    end
  end

  def initialize(site, stage, options = {})
    @site, @stage, @options = site, stage, options
  end

  def cdn_file
    @cdn_file ||= CDNFile.new(
      file,
      destination,
      s3_options,
      options
    )
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

private

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

  def destination
    { bucket: S3Wrapper.buckets['sublimevideo'], path: path }
  end

  def path
    if stage == 'stable'
      "js/#{token}.js"
    else
      "js/#{token}-#{stage}.js"
    end
  end

  def s3_options
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
