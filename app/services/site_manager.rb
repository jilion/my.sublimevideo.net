class SiteManager
  attr_reader :site

  # Delayable methods
  def self.subscribe_site_to_addon(site_id, addon_name, addon_plan_id)
    new(::Site.find(site_id)).update_billable_items({}, { addon_name => addon_plan_id })
  end

  def self.update_billable_items(site_id, designs, addon_plans, options = {})
    new(::Site.find(site_id)).update_billable_items(designs, addon_plans, options)
  end

  def initialize(site)
    @site = site
  end

  def create
    _transaction_with_graceful_fail do
      site.save!
      _create_default_kit!
      _set_default_designs
      _set_default_addon_plans
      _touch_timestamps(%w[loaders settings])
      site.save!
      _delay_jobs(:loader, :settings, :rank)
      _increment_librato('create')
    end
  end

  def update(attributes)
    _transaction_with_graceful_fail do
      site.attributes = attributes
      _touch_timestamps('settings')
      site.save!
      _delay_jobs(:settings)
      _increment_librato('update')
    end
  end

  # designs => { "classic"=>"0", "light"=>"42" }
  # addon_plans => { "logo"=>"0", "support"=>"88" }
  def update_billable_items(designs, addon_plans, options = {})
    Site.transaction do
      _update_design_subscriptions(designs || {}, options)
      _update_addon_subscriptions(addon_plans || {}, options)
      _touch_timestamps(%w[loaders settings addons])
      site.save!
    end
    _delay_jobs(:loader, :settings)
  end

  # called from app/models/site.rb
  def suspend_billable_items
    site.billable_items.map(&:suspend!)
  end

  # called from app/models/site.rb
  def unsuspend_billable_items
    _set_default_designs
    site.billable_items.where(state: 'suspended').each do |billable_item|
      billable_item.state = _new_billable_item_state(billable_item.item, force: 'sponsored')
      billable_item.save!
    end
  end

  # called from app/models/site.rb
  def cancel_billable_items
    site.billable_items.destroy_all
  end

  private

  def _transaction_with_graceful_fail
    Site.transaction do
      yield
    end
    true
  rescue => ex
    Rails.logger.info ex.inspect
    false
  end

  def _touch_timestamps(types)
    Array(types).each do |type|
      site.send("#{type}_updated_at=", Time.now.utc)
    end
  end

  def _delay_jobs(*jobs)
    LoaderGenerator.delay(queue: 'my').update_all_stages!(site.id) if jobs.include?(:loader)
    SettingsGenerator.delay(queue: 'my').update_all!(site.id) if jobs.include?(:settings)
    RankSetter.delay(queue: 'my-low').set_ranks(site.id) if jobs.include?(:rank)
  end

  def _create_default_kit!
    site.kits.create!(name: 'Default player')
    site.default_kit = site.kits.first
  end

  def _set_default_designs(options = {})
    _update_design_subscriptions({
      classic: Design.get('classic').id,
      light: Design.get('light').id,
      flat: Design.get('flat').id
    }, options)
  end

  def _update_or_build_subscription(item, options)
    if billable_item = site.billable_items.with_item(item).first
      _update_billable_item_state!(billable_item, options)
    elsif item.not_custom? || options[:allow_custom]
      _build_subscription(item, options)
    end
  end

  def _update_design_subscription(design_name, design_id, options)
    design = Design.get(design_name)

    case design_id
    when '0'
      _cancel_design(design)
    else
      _update_or_build_subscription(design, options)
    end
  end

  def _update_addon_subscription(addon_name, addon_plan_id, options)
    addon = Addon.get(addon_name)

    case addon_plan_id
    when '0'
      _cancel_addon(addon)
    else
      addon_plan = AddonPlan.find(addon_plan_id)
      _cancel_addon(addon, except_addon_plan: addon_plan)
      _update_or_build_subscription(addon_plan, options)
    end
  end

  def _update_design_subscriptions(design_subscriptions, options = {})
    design_subscriptions.each do |design_name, design_id|
      _update_design_subscription(design_name, design_id, options)
    end
  end

  def _update_addon_subscriptions(addon_plan_subscriptions, options = {})
    addon_plan_subscriptions.each do |addon_name, addon_plan_id|
      _update_addon_subscription(addon_name, addon_plan_id, options)
    end
  end

  def _set_default_addon_plans
    _update_addon_subscriptions(_free_addon_plans_subscriptions_hash, force: 'sponsored')
  end

  def _cancel_design(design)
    site.billable_items.with_item(design).destroy_all
  end

  def _cancel_addon(addon, options = {})
    addon_plan_ids_to_cancel  = addon.plans.pluck(:id)
    addon_plan_ids_to_cancel -= [options[:except_addon_plan].id] if options[:except_addon_plan]

    site.billable_items.addon_plans.where(item_id: addon_plan_ids_to_cancel).destroy_all
  end

  def _update_billable_item_state!(billable_item, options)
    new_state = _new_billable_item_state(billable_item.item, options)
    return if new_state == billable_item.state

    billable_item.state = new_state
    billable_item.save!
  end

  def _build_subscription(design_or_addon, options)
    site.billable_items.build(item: design_or_addon, state: _new_billable_item_state(design_or_addon, options))
  end

  def _free_addon_plans_subscriptions_hash(*args)
    hash = AddonPlan.free_addon_plans(*args).reduce({}) do |h, addon_plan|
      h[addon_plan.addon_name.to_sym] = addon_plan.id
      h
    end

    # These addon plans will be sponsored
    hash[:logo] = AddonPlan.get('logo', 'custom').id
    hash[:social_sharing] = AddonPlan.get('social_sharing', 'standard').id
    hash[:embed] = AddonPlan.get('embed', 'auto').id
    hash[:cuezones] = AddonPlan.get('cuezones', 'standard').id
    hash[:google_analytics] = AddonPlan.get('google_analytics', 'standard').id

    hash
  end

  def _new_billable_item_state(design_or_addon, options = {})
    if options[:force]
      if design_or_addon.beta? || !design_or_addon.free?
        options[:force]
      else
        'subscribed'
      end
    elsif design_or_addon.beta?
      'beta'
    elsif design_or_addon.free?
      'subscribed'
    else
      'trial'
    end
  end

  def _increment_librato(event)
    Librato.increment 'sites.events', source: event
  end

end
