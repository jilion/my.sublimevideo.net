require 'tempfile'
require_dependency 'cdn/file'
require_dependency 'app/mangler'

module Service
  Settings = Struct.new(:site, :type, :options, :file, :cdn_file) do
    self::TYPES = %w[license settings]
    self::SITE_FIELDS = %w[plan_id accessible_stage hostname extra_hostnames dev_hostnames path wildcard badged]

    delegate :upload!, :delete!, :present?, to: :cdn_file

    def self.update_all_types!(site_id, options = {})
      site = ::Site.find(site_id)
      changed = []
      if site.state == 'active'
        changed << new(site, 'license', options).upload!
        unless site.accessible_stage == 'stable'
          changed << new(site, 'settings', options).upload!
        end
      else
        self::TYPES.each { |type| new(site, type, options).delete! }
      end
      site.touch(:settings_updated_at) if changed.any? && options[:touch] != false
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

    def old_license
      hash = { h: [site.hostname] }
      hash[:h] += site.extra_hostnames.split(/,\s*/) if site.extra_hostnames?
      hash[:d]  = site.dev_hostnames.split(/,\s*/) if site.dev_hostnames?
      hash[:w]  = site.wildcard if site.wildcard?
      hash[:p]  = site.path if site.path?
      hash[:b]  = site.badged
      hash[:s]  = true unless site.in_free_plan? # SSL
      hash[:r]  = true if site.plan_stats_retention_days != 0 # Realtime Stats
      hash[:m]  = site.player_mode
      hash
    end

    def license
      hash = { hosts: [site.hostname] }
      hash[:hosts]    += (site.extra_hostnames || '').split(/,\s*/)
      hash[:dev_hosts] = (site.dev_hostnames || '').split(/,\s*/)
      hash[:path]      = site.path
      hash[:wildcard]  = site.wildcard
      hash[:stage]     = site.accessible_stage
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
      site.kits.includes(:design).inject({}) do |hash, kit|
        hash[kit.name] = {}
        hash[kit.name][:skin] = { id: kit.skin_token }
        hash[kit.name][:plugins] = kits_plugins(kit, nil)
        hash
      end
    end

    def default_kit
      "default"
    end

    def mangle(hash)
      App::Mangler.mangle(hash)
    end

  private

    def addon_plans
      @addon_plans ||= site.addon_plans.includes(:addon, settings_templates: :plugin)
    end

    def addon_plans_without_plugins
      @addon_plans_without_plugins ||= addon_plans.select { |ap|
        ap.settings_templates.present? && ap.settings_templates.none? { |st| st.plugin.present? }
      }
    end

    def addon_plans_with_plugins
      @addon_plans_with_plugins ||= addon_plans.select { |ap|
        ap.settings_templates.present? && ap.settings_templates.any? { |st| st.plugin.present? }
      }
    end

    def kits_plugins(kit, parent_addon_id)
      addon_plans = addon_plans_with_plugins.select { |ap| ap.addon.parent_addon_id == parent_addon_id }
      addon_plans.inject({}) { |hash, addon_plan|
        hash[addon_plan.kind] = {}
        unless (plugins = kits_plugins(kit, addon_plan.addon_id)).empty?
          hash[addon_plan.kind][:plugins] = plugins
        end
        template = addon_plan.settings_templates.detect { |st| st.plugin.app_design_id.in?([nil, kit.app_design_id]) }
        hash[addon_plan.kind][:settings] = addon_plan_settings(template.template, kit.settings[addon_plan.addon.name])
        hash[addon_plan.kind][:allowed_settings] = addon_plan_allowed_settings(template.template)
        hash[addon_plan.kind][:id] = template.plugin.token
        unless (condition = template.plugin.condition).empty?
          hash[addon_plan.kind][:condition] = condition
        end
        hash
      }
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
      template_path = Rails.root.join("app/templates/app/#{template_file}")
      template = ERB.new(File.new(template_path).read)
      file = Tempfile.new("s-#{site.token}.js", "#{Rails.root}/tmp")
      file.print template.result(binding)
      file.flush
      file
    end

    def template_file
      case type
      when 'license'; 'settings-old.js.erb'
      when 'settings'; 'settings.js.erb'
      end
    end

    def destinations
      case type
      when 'license'
        [{
          bucket: S3.buckets['sublimevideo'],
          path: "l/#{site.token}.js"
        },{
          bucket: S3.buckets['licenses'],
          path: "licenses/#{site.token}.js"
        }]
      when 'settings'
        [{
          bucket: S3.buckets['sublimevideo'],
          path: "s/#{site.token}.js"
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
