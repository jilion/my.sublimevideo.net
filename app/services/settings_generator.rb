require 'tempfile'

# models
require 'app'

# wrappers
require 's3_wrapper'
require 'cdn_file'

# services
require 'player_mangler'
require 'settings_formatter'

class SettingsGenerator
  attr_reader :site, :options

  def initialize(site, options = {})
    @site, @options = site, options
  end

  def self.update_all!(site_id, options = {})
    site = Site.find(site_id)
    generator = new(site, options)

    if site.active?
      generator.upload!
    else
      generator.delete!
    end
  end

  def cdn_files
    @cdn_files ||= [
      CDNFile.new(_generate_file, _path('s'), _s3_headers),
      CDNFile.new(_generate_file('new-'), _path('s2'), _s3_headers)
    ]
  end

  def license
    hash = { hosts: [site.hostname] }
    hash[:hosts]        += (site.extra_hostnames || '').split(/,\s*/)
    hash[:staging_hosts] = (site.staging_hostnames || '').split(/,\s*/)
    hash[:dev_hosts]     = (site.dev_hostnames || '').split(/,\s*/)
    hash[:path]          = site.path
    hash[:wildcard]      = site.wildcard
    hash[:stage]         = site.accessible_stage
    hash
  end

  def app_settings
    _addon_plans_without_plugins.reduce({}) do |hash, addon_plan|
      template = addon_plan.settings.first.template
      hash[addon_plan.kind] = {}
      hash[addon_plan.kind][:settings] = _addon_plan_settings(template)
      hash[addon_plan.kind][:allowed_settings] = _addon_plan_allowed_settings(template)
      hash
    end
  end

  def kits(with_module = false)
    site.kits.includes(:design).order(:identifier).reduce({}) do |hash, kit|
      hash[kit.identifier] = {}
      hash[kit.identifier][:skin] = if with_module
        { module: kit.skin_mod }
      else
        { id: kit.skin_token }
      end
      hash[kit.identifier][:plugins] = _kits_plugins(kit, nil, with_module)
      hash
    end
  end

  def default_kit
    site.default_kit.identifier
  end

  # @deprecated
  #
  def mangle(hash)
    PlayerMangler.mangle(hash)
  end

  def format(hash)
    SettingsFormatter.format(hash)
  end

  def upload!
    cdn_files.map(&:upload!)
    _increment_librato('update')
  end

  def delete!
    cdn_files.map(&:delete!)
    _increment_librato('delete')
  end

private

  def _addon_plans
    @_addon_plans ||= site.addon_plans.includes(:addon, settings: :plugin).order(:id)
  end

  def _addon_plans_without_plugins
    @_addon_plans_without_plugins ||= _addon_plans.select do |addon_plan|
      addon_plan.settings.present? &&
      addon_plan.settings.none? { |st| st.app_plugin_id.present? }
    end
  end

  def _addon_plans_with_plugins(kit)
    @_addon_plans_with_plugins ||= {}
    @_addon_plans_with_plugins[kit.id] ||= _addon_plans.select do |addon_plan|
      addon_plan.settings.present? &&
      addon_plan.settings.any? { |st| st.app_plugin_id.present? } &&
      addon_plan.settings_for(kit.design).present?
    end
  end

  def _kits_plugins(kit, parent_addon_id, with_module)
    addon_plans = _addon_plans_with_plugins(kit).select { |ap| ap.addon.parent_addon_id == parent_addon_id }
    addon_plans.reduce({}) do |hash, addon_plan|
      hash[addon_plan.kind] = {}

      unless (plugins = _kits_plugins(kit, addon_plan.addon_id, with_module)).empty?
        hash[addon_plan.kind][:plugins] = plugins
      end

      if template = addon_plan.settings_for(kit.design)
        hash[addon_plan.kind][:settings] = _addon_plan_settings(template.template, kit.settings[addon_plan.addon_name])
        hash[addon_plan.kind][:allowed_settings] = _addon_plan_allowed_settings(template.template)
        hash[addon_plan.kind][:id] = template.plugin.token
        hash[addon_plan.kind][:module] = template.plugin.mod if with_module
        unless (condition = template.plugin.condition).empty?
          hash[addon_plan.kind][:condition] = condition
        end
      end

      hash.reject { |k, v| v.empty? }
    end
  end

  def _addon_plan_settings(template, kit_settings = nil)
    template.reduce({}) do |hash, (key, value)|
      kit_value = kit_settings && kit_settings[key]
      hash[key] = kit_value.nil? ? value[:default] : kit_value
      hash
    end
  end

  def _addon_plan_allowed_settings(template)
    template.reduce({}) do |hash, (key, value)|
      hash[key] = value.slice(:values, :range)
      hash
    end
  end

  def _generate_file(prefix = '')
    template_path = Rails.root.join('app', 'templates', "#{prefix}settings.js.erb")
    template = ERB.new(File.new(template_path).read)
    file = Tempfile.new("s-#{@site.token}.js", Rails.root.join('tmp'))
    file.print template.result(binding)
    file.flush
    file
  end

  def _path(folder)
    "#{folder}/#{site.token}.js"
  end

  def _s3_headers
    {
      'Cache-Control' => 's-maxage=300, max-age=120, public', # 5 minutes / 2 minutes
      'Content-Type'  => 'text/javascript',
      'x-amz-acl'     => 'public-read'
    }
  end

  def _increment_librato(action)
    Librato.increment "settings.#{action}", source: 'settings'
  end

end
