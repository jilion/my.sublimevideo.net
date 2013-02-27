class SiteManager
  attr_reader :site

  # Delayable methods
  def self.subscribe_site_to_addon(site_id, addon_name, addon_plan_id)
    new(::Site.find(site_id)).update_billable_items({}, { addon_name => addon_plan_id })
  end

  def self.update_billable_items(site_id, app_designs, addon_plans, options = {})
    new(::Site.find(site_id)).update_billable_items(app_designs, addon_plans, options)
  end

  def initialize(site)
    @site = site
  end

  def create
    Site.transaction do
      site.save!
      create_default_kit!

      set_default_app_designs
      set_default_addon_plans
      site.loaders_updated_at  = Time.now.utc
      site.settings_updated_at = Time.now.utc
      site.save!
    end
    LoaderGenerator.delay.update_all_stages!(site.id)
    SettingsGenerator.delay.update_all!(site.id)
    RankSetter.delay(queue: 'low').set_ranks(site.id)
    Librato.increment 'sites.events', source: 'create'
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def update(attributes)
    Site.transaction do
      site.attributes = attributes
      site.settings_updated_at = Time.now.utc
      site.save!
    end
    SettingsGenerator.delay.update_all!(site.id)
    Librato.increment 'sites.events', source: 'update'
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  # app_designs => { "classic"=>"0", "light"=>"42" }
  # addon_plans => { "logo"=>"0", "support"=>"88" }
  def update_billable_items(app_designs, addon_plans, options = {})
    Site.transaction do
      update_design_subscriptions(app_designs || {}, options)
      update_addon_subscriptions(addon_plans || {}, options)
      site.loaders_updated_at  = Time.now.utc
      site.settings_updated_at = Time.now.utc
      site.addons_updated_at   = Time.now.utc
      site.save!
    end
    LoaderGenerator.delay.update_all_stages!(site.id)
    SettingsGenerator.delay.update_all!(site.id)
  end

  # called from app/models/site.rb
  def suspend_billable_items
    site.billable_items.map(&:suspend!)
  end

  # called from app/models/site.rb
  def unsuspend_billable_items
    set_default_app_designs
    if site.plan_id?
      update_addon_subscriptions(AddonPlan.free_addon_plans(reject: %w[logo stats support]))
      case site.plan.name
      when 'plus'
        # Sponsor real-time stats
        update_addon_subscriptions({
          stats: AddonPlan.get('stats', 'realtime').id,
          support: AddonPlan.get('support', 'standard').id
        }, force: 'sponsored')
        update_addon_subscriptions({
          logo: AddonPlan.get('logo', 'disabled').id
        }, force: 'subscribed')
      when 'premium'
        # Sponsor VIP email support
        update_addon_subscriptions({
          support: AddonPlan.get('support', 'vip').id
        }, force: 'sponsored')
        update_addon_subscriptions({
          logo: AddonPlan.get('logo', 'disabled').id,
          stats: AddonPlan.get('stats', 'realtime').id
        }, force: 'subscribed')
      end
      site.save!
    else
      site.billable_items.where(state: 'suspended').each do |billable_item|
        billable_item.state = new_billable_item_state(billable_item.item)
        billable_item.save!
      end
    end
  end

  # called from app/models/site.rb
  def cancel_billable_items
    site.billable_items.destroy_all
  end

  private

  def create_default_kit!
    site.kits.create!(name: 'Default player')
    site.default_kit = site.kits.first
  end

  def set_default_app_designs(options = {})
    update_design_subscriptions({
      classic: App::Design.get('classic').id,
      light: App::Design.get('light').id,
      flat: App::Design.get('flat').id
    }, options)
  end

  def set_default_addon_plans
    update_addon_subscriptions(AddonPlan.free_addon_plans)
  end

  def update_design_subscriptions(design_subscriptions, options = {})
    design_subscriptions.each do |design_name, design_id|
      update_design_subscription(design_name, design_id, options)
    end
  end

  def update_addon_subscriptions(addon_plan_subscriptions, options = {})
    addon_plan_subscriptions.each do |addon_name, addon_plan_id|
      update_addon_subscription(addon_name, addon_plan_id, options)
    end
  end

  def update_design_subscription(design_name, design_id, options)
    design = App::Design.get(design_name)

    case design_id
    when '0'
      cancel_design(design)
    else
      if billable_item = site.billable_items.with_item(design).first
        update_billable_item_state!(billable_item, options)
      elsif design.not_custom? || options[:allow_custom]
        build_subscription(design, options)
      end
    end
  end

  def update_addon_subscription(addon_name, addon_plan_id, options)
    addon = Addon.get(addon_name)

    case addon_plan_id
    when '0'
      cancel_addon(addon)
    else
      addon_plan = AddonPlan.find(addon_plan_id)

      cancel_addon(addon, except_addon_plan: addon_plan)

      if billable_item = site.billable_items.with_item(addon_plan).first
        update_billable_item_state!(billable_item, options)
      elsif addon_plan.not_custom? || options[:allow_custom]
        build_subscription(addon_plan, options)
      end
    end
  end

  def cancel_design(design)
    site.billable_items.with_item(design).destroy_all
  end

  def cancel_addon(addon, options = {})
    addon_plan_ids_to_cancel  = addon.plans.pluck(:id)
    addon_plan_ids_to_cancel -= [options[:except_addon_plan].id] if options[:except_addon_plan]

    site.billable_items.addon_plans.where{ item_id >> addon_plan_ids_to_cancel }.destroy_all
  end

  def update_billable_item_state!(billable_item, options)
    new_state = new_billable_item_state(billable_item.item, options)
    return if new_state == billable_item.state

    billable_item.state = new_state
    billable_item.save!
  end

  def build_subscription(design_or_addon, options)
    site.billable_items.build({ item: design_or_addon, state: new_billable_item_state(design_or_addon, options) }, without_protection: true)
  end

  def new_billable_item_state(design_or_addon, options = {})
    if options[:suspended]
      'suspended'
    elsif options[:force]
      if design_or_addon.beta? || !design_or_addon.free?
        options[:force]
      else
        'subscribed'
      end
    elsif design_or_addon.beta?
      'beta'
    elsif design_or_addon.free? || TrialHandler.new(site).out_of_trial?(design_or_addon)
      'subscribed'
    else
      'trial'
    end
  end
end
