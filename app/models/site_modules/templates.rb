module SiteModules::Templates
  extend ActiveSupport::Concern

  module ClassMethods

    # delayed method
    def update_loader_and_license(site_id, options = {})
      site = Site.find(site_id)
      transaction do
        if options[:loader]
          purge_loader = site.loader.present?
          site.set_template(:loader)
        end
        if options[:license]
          purge_license = site.license.present?
          site.license_hash
          site.set_template(:license)
        end
        site.cdn_up_to_date = true
        site.save!

        site.purge_template(:loader) if purge_loader
        site.purge_template(:license) if purge_license
      end
    end

    # delayed method
    def remove_loader_and_license(site_id)
      site = Site.find(site_id)
      transaction do
        site.remove_loader, site.remove_license = true, true
        site.cdn_up_to_date = false
        %w[loader license].each { |template| site.purge_template(template) }
        site.save!
      end
    end

  end

  # ====================
  # = Instance Methods =
  # ====================

  module InstanceMethods

    def license_hash
      hash = { h: [hostname] }
      hash[:h] += extra_hostnames.split(', ') if extra_hostnames?
      hash[:d] = dev_hostnames.split(', ') if dev_hostnames?
      hash[:w] = wildcard if wildcard?
      hash[:p] = path if path?
      hash[:b] = badged
      hash[:s] = true unless in_free_plan? # SSL
      hash[:r] = true if stats_retention_days != 0 # Realtime Stats
      hash
    end

    def license_js_hash
      license_hash.to_s.gsub(/:|\s/, '').gsub(/\=\>/, ':')
    end

    def purge_template(name)
      mapping = { loader: 'js', license: 'l' }
      VoxcastCDN.purge("/#{mapping[name.to_sym]}/#{token}.js")
    end

    def set_template(name)
      template = ERB.new(File.new(Rails.root.join("app/templates/sites/#{name.to_s}.js.erb")).read)

      tempfile = Tempfile.new(name.to_s, "#{Rails.root}/tmp")
      tempfile.print template.result(binding)
      tempfile.flush

      self.send("#{name}=", tempfile)
    end

  private

    def settings_changed?
      (changed & %w[hostname extra_hostnames dev_hostnames path wildcard badged stats_trial_started_at]).present?
    end

    # before_save
    def prepare_cdn_update
      @loader_needs_update = @license_needs_update = false
      if state_change == ['suspended', 'active']
        @loader_needs_update = @license_needs_update = true
      else
        @loader_needs_update  = plan_id_changed? || player_mode_changed?
        @license_needs_update = plan_id_changed? || settings_changed?
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

end

# == Schema Information
#
# Table name: sites
#
#  license                                    :string(255)
#  loader                                     :string(255)
#  cdn_up_to_date                             :boolean
