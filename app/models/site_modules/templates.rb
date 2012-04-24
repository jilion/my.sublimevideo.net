module SiteModules::Templates
  extend ActiveSupport::Concern

  module ClassMethods
    TEMPLATES = [:loader, :license]

    # delayed method
    def update_loader_and_license(site_id, templates = {})
      site = Site.find(site_id)
      templates_to_purge = []

      templates.each do |template, needs_update|
        if needs_update
          templates_to_purge << template if site.send(template).present?
          site.set_template(template)
        end
      end
      site.cdn_up_to_date = true
      site.save!

      templates_to_purge.each { |template| site.purge_template(template) }

      PusherWrapper.trigger("private-#{site.token}", 'cdn_status', up_to_date: true)
    end

    # delayed method
    def remove_loader_and_license(site_id)
      site = Site.find(site_id)

      site.remove_loader, site.remove_license = true, true
      site.cdn_up_to_date = false
      site.save!

      TEMPLATES.each { |template| site.purge_template(template) }
    end
  end

  def license_hash
    hash = { h: [hostname] }
    hash[:h] += extra_hostnames.split(', ') if extra_hostnames?
    hash[:d] = dev_hostnames.split(', ') if dev_hostnames?
    hash[:w] = wildcard if wildcard?
    hash[:p] = path if path?
    hash[:b] = badged
    hash[:s] = true unless in_free_plan? # SSL
    hash[:r] = true if plan_id? && plan_stats_retention_days != 0 # Realtime Stats
    hash
  end

  def license_js_hash
    license_hash.to_s.gsub(/:|\s/, '').gsub(/\=\>/, ':')
  end

  def purge_template(name)
    mapping = { loader: 'js', license: 'l' }
    VoxcastCDN.purge("/#{mapping[name.to_sym]}/#{token}.js")
  end

  def set_template(name, options = {})
    name = name.to_s
    return unless %w[loader license].include?(name)

    template = begin
      prefix   = options[:prefix].to_s.present? ? "#{options[:prefix].to_s}_" : ''
      filename = Rails.root.join("app/templates/sites/#{prefix}#{name}.js.erb")
      ERB.new(File.new(filename).read)
    rescue Errno::ENOENT
      options[:prefix] = nil
      retry
    end

    tempfile = Tempfile.new(["#{name}-#{token}-#{Time.now.utc}", '.js'], "#{Rails.root}/tmp")
    tempfile.print template.result(binding)
    tempfile.flush

    self.send("#{name}=", tempfile)
  end

private

  def settings_changed?
    (changed & %w[hostname extra_hostnames dev_hostnames path wildcard badged]).present?
  end

  # before_save
  def prepare_cdn_update
    @loader_needs_update = @license_needs_update = false
    if state_change == ['suspended', 'active']
      @loader_needs_update = @license_needs_update = true
    else
      @loader_needs_update  = plan_id? && (plan_id_changed? || player_mode_changed?)
      @license_needs_update = plan_id? && (plan_id_changed? || settings_changed?)
    end
    self.cdn_up_to_date = !(@loader_needs_update || @license_needs_update)

    true
  end

  # after_save
  def execute_cdn_update
    if @loader_needs_update || @license_needs_update
      Site.delay.update_loader_and_license(self.id, loader: @loader_needs_update, license: @license_needs_update)
    end
    @loader_needs_update = @license_needs_update = false
  end

  # after_transition :to => [:suspended, :archived]
  def delay_remove_loader_and_license
    Site.delay.remove_loader_and_license(self.id)
  end

end
