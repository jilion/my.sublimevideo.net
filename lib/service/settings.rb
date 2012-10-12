# TODO
# - add component list permission (and version check on player_mode)

require 'tempfile'
require_dependency 'cdn/file'

module Service
  Settings = Struct.new(:site, :type, :options, :file, :cdn_file) do
    self::TYPES = %w[license settings]
    self::SITE_FIELDS = %w[plan_id accessible_stage hostname extra_hostnames dev_hostnames path wildcard badged]
    self::MANGLE_MAP = {
      "plugins" => "ka",
      "skin" => "kb",
      "imageViewer" => "kc",
      "lightbox" => "kd",
      "videoPlayer" => "ke",
      "stats" => "kf",
      "controls" => "kg",
      "startView" => "kh",
      "badge" => "ki",
      "cuepoints" => "kl",
      "sharing" => "km",
      "id" => "kn",
      "settings" => "ko",
      "allowedSettings" => "kp",
      "condition" => "kq",

      "f =>ashForced" => "ta",
      "fullwindowForced" => "tb",
      "stopOnEnd" => "tc",
      "fullmodeEnabled" => "td",
      "volumeEnabled" => "te",
      "autoplay" => "tf",
      "overlayColor" => "tg",
      "overlayOpacity" => "th",
      "closeButtonType" => "ti",
      "closeButtonPosition" => "tl",
      "enable" => "tm",
      "realtime" => "tn",
      "position" => "to",
      "url" => "tp",
      "controls" => "tq",
      "overlayEnabled" => "tr",
      "twitterURL" => "ts",
      "facebookURL" => "tt",
      "embedURL" => "tu",
      "embedWidth" => "tv",
      "embedHeight" => "tz",
      "app" => "sa",
      "sublimeSkin" => "sb",
      "sublime" => "sc" ,
      "flat" => "sd",
      "light" => "se",
      "twit" => "sf",
      "html5" => "sg",
      "sublimeVideo" => "sh",
      "SVVideoAppPlugin" => "si",
      "sublimeLightbox" => "sl",
      "SVLightboxAppPlugin" => "sm",
      "sublimeImage" => "sn",
      "SVImageAppPlugin" => "so",
      "SVBadgeController" => "sp",
      "SVControls" => "sq",
      "FLTControls" => "sr",
      "LGTControls" => "ss",
      "TWTControls" => "st",
      "HTML5Controls" => "su",
      "SVStartController" => "sv",
      "SVSharingButtons" => "sz"
    }

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

    def hash
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

  private

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
        'Cache-Control' => 'max-age=120, public', # 2 minutes
        'Content-Type'  => 'text/javascript',
        'x-amz-acl'     => 'public-read'
      }
    end

  end
end
