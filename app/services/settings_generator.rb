require 'tempfile'

class SettingsGenerator
  attr_reader :site, :options

  delegate :upload!, :delete!, :present?, to: :cdn_file

  def self.update_all!(site_id, options = {})
    site = Site.find(site_id)
    if site.state == 'active'
      new(site, options).upload!
      Librato.increment 'settings.update', source: 'settings'
    else
      new(site, options).delete!
      Librato.increment 'settings.delete', source: 'settings'
    end
  end

  def initialize(site, options = {})
    @site, @options = site, options
  end

  def cdn_file
    @cdn_file ||= CDNFile.new(file, path, s3_headers)
  end

  def file
    @file ||= generate_file
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
    addon_plans_without_plugins.inject({}) do |hash, addon_plan|
      template = addon_plan.settings_templates.first.template
      hash[addon_plan.kind] = {}
      hash[addon_plan.kind][:settings] = addon_plan_settings(template)
      hash[addon_plan.kind][:allowed_settings] = addon_plan_allowed_settings(template)
      hash
    end
  end

  def kits
    site.kits.includes(:design).order(:identifier).inject({}) do |hash, kit|
      hash[kit.identifier] = {}
      hash[kit.identifier][:skin] = { id: kit.skin_token }
      hash[kit.identifier][:plugins] = kits_plugins(kit, nil)
      hash
    end
  end

  def default_kit
    site.default_kit.identifier
  end

  def mangle(hash)
    PlayerMangler.mangle(hash)
  end

private

  def addon_plans
    @addon_plans ||= site.addon_plans.includes(:addon, settings_templates: :plugin).order(:id)
  end

  def addon_plans_without_plugins
    @addon_plans_without_plugins ||= addon_plans.select do |addon_plan|
      addon_plan.settings_templates.present? &&
      addon_plan.settings_templates.none? { |st| st.app_plugin_id.present? }
    end
  end

  def addon_plans_with_plugins(kit)
    @addon_plans_with_plugins ||= {}
    @addon_plans_with_plugins[kit.id] ||= addon_plans.select do |addon_plan|
      addon_plan.settings_templates.present? &&
      addon_plan.settings_templates.any? { |st| st.app_plugin_id.present? } &&
      addon_plan.settings_template_for(kit.design).present?
    end
  end

  def kits_plugins(kit, parent_addon_id)
    addon_plans = addon_plans_with_plugins(kit).select { |ap| ap.addon.parent_addon_id == parent_addon_id }
    addon_plans.inject({}) do |hash, addon_plan|
      hash[addon_plan.kind] = {}

      unless (plugins = kits_plugins(kit, addon_plan.addon_id)).empty?
        hash[addon_plan.kind][:plugins] = plugins
      end

      if template = addon_plan.settings_template_for(kit.design)
        hash[addon_plan.kind][:settings] = addon_plan_settings(template.template, kit.settings[addon_plan.addon.name])
        hash[addon_plan.kind][:allowed_settings] = addon_plan_allowed_settings(template.template)
        hash[addon_plan.kind][:id] = template.plugin.token
        unless (condition = template.plugin.condition).empty?
          hash[addon_plan.kind][:condition] = condition
        end
      end

      hash.reject { |k, v| v.empty? }
    end
  end

  def addon_plan_settings(template, kit_settings = nil)
    template.inject({}) do |hash, (key, value)|
      kit_value = kit_settings && kit_settings[key]
      hash[key] = kit_value.nil? ? value[:default] : kit_value
      hash
    end
  end

  def addon_plan_allowed_settings(template)
    template.inject({}) do |hash, (key, value)|
      hash[key] = value.slice(:values, :range)
      hash
    end
  end

  def generate_file
    template_path = Rails.root.join('app', 'templates', template_file)
    template = ERB.new(File.new(template_path).read)
    file = Tempfile.new("s-#{@site.token}.js", Rails.root.join('tmp'))
    file.print template.result(binding)
    file.flush
    file
  end

  def template_file
    'settings.js.erb'
  end

  def path
    "s/#{site.token}.js"
  end

  def s3_headers
    {
      'Cache-Control' => 's-maxage=300, max-age=120, public', # 5 minutes / 2 minutes
      'Content-Type'  => 'text/javascript',
      'x-amz-acl'     => 'public-read'
    }
  end
end
