module Site::Templates
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

  module InstanceMethods

    def license_hash
      hash = {}
      unless in_dev_plan?
        hash[:h] = [hostname]
        hash[:h] += extra_hostnames.split(', ') if extra_hostnames?
        hash[:p] = path if path.present?
      end
      hash[:d] = dev_hostnames.split(', ') if dev_hostnames?
      hash[:w] = wildcard if wildcard?
      hash
    end

    def license_js_hash
      license_hash.to_s.gsub(/:|\s/, '').gsub(/\=\>/, ':')
    end

    def purge_template(name)
      mapping = { loader: 'js', license: 'l' }
      raise "Unknown template name!" unless mapping.keys.include?(name.to_sym)
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
      (changed & %w[hostname extra_hostnames dev_hostnames path wildcard]).present?
    end

    # before_save
    def prepare_cdn_update
      if state_changed? && active? && state_was == 'suspended'
        @loader_needs_update = true
        @license_needs_update = true
      else
        @loader_needs_update  = (player_mode_changed? && persisted?) || (plan_id_changed? && plan_id_was.nil?)
        @license_needs_update = pending_plan_id.nil? && (settings_changed? || (plan_id_changed? && (plan_id_was.nil? || in_dev_plan? || Plan.find(plan_id_was).dev_plan?)))
      end

      self.cdn_up_to_date = !(@loader_needs_update || @license_needs_update) if persisted?

      true
    end

    # after_save
    def execute_cdn_update
      if @loader_needs_update || @license_needs_update
        Site.delay.update_loader_and_license(self.id, :loader => @loader_needs_update, :license => @license_needs_update)
      end
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
