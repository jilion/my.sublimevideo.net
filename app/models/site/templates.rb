module Site::Templates

  def self.included(base)
    base.send :extend, ClassMethods
  end

  module ClassMethods
    # delayed method
    def update_loader_and_license(site_id, options = {})
      site = Site.find(site_id)
      transaction do
        begin
          if options[:loader]
            purge_loader = site.loader.present?
            site.set_template("loader")
            site.purge_template("loader") if purge_loader
          end
          if options[:license]
            purge_license = site.license.present?
            site.set_template("license")
            site.purge_template("license") if purge_license
          end
          site.cdn_up_to_date = true
          site.save!
        rescue => ex
          Notify.send(ex.message, :exception => ex)
        end
      end
    end

    # delayed method
    def remove_loader_and_license(site_id)
      site = Site.find(site_id)
      transaction do
        begin
          site.remove_loader, site.remove_license = true, true
          site.cdn_up_to_date = false
          %w[loader license].each { |template| site.purge_template(template) }
          site.save!
        rescue => ex
          Notify.send(ex.message, :exception => ex)
        end
      end
    end
  end

  # ====================
  # = Instance Methods =
  # ====================

  def license_json
    hash = { h: [], w: wildcard }
    unless in_dev_plan?
      hash[:h] << [hostname, path].compact.join('/')
      hash[:h] += extra_hostnames.split(', ').map { |hostname| [hostname, path].compact.join('/') } if extra_hostnames?
    end
    hash[:h] += dev_hostnames.split(', ')
    hash.to_json
  end

  def set_template(name)
    template = ERB.new(File.new(Rails.root.join("app/templates/sites/#{name}.js.erb")).read)

    tempfile = Tempfile.new(name, "#{Rails.root}/tmp")
    tempfile.print template.result(binding)
    tempfile.flush

    self.send("#{name}=", tempfile)
  end

  def purge_template(name)
    mapping = { loader: 'js', license: 'l' }
    raise "Unknown template name!" unless mapping.keys.include?(name.to_sym)
    VoxcastCDN.purge("/#{mapping[name.to_sym]}/#{token}.js")
  end

  def set_template(name)
    template = ERB.new(File.new(Rails.root.join("app/templates/sites/#{name}.js.erb")).read)

    tempfile = Tempfile.new(name, "#{Rails.root}/tmp")
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
    @loader_needs_update  = false
    @license_needs_update = false
    common_conditions = new_record? || (state_changed? && active?)

    if common_conditions || player_mode_changed?
      self.cdn_up_to_date  = false
      @loader_needs_update = true
    end

    if common_conditions || settings_changed? || plan_id_changed?
      self.cdn_up_to_date   = false
      @license_needs_update = true
    end
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

Site.send :include, Site::Templates

# == Schema Information
#
# Table name: sites
#
#  license                                    :string(255)
#  loader                                     :string(255)
#  cdn_up_to_date                             :boolean
