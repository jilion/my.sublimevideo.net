require 'site_manager'

class AddonsSubscriber
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

  # designs => { "classic"=>"0", "light"=>"42" }
  # addon_plans => { "logo"=>"0", "support"=>"88" }
  def update_billable_items(designs, addon_plans, options = {})
    site_manager = SiteManager.new(site)
    site_manager.transaction_with_graceful_fail do
      _update_design_subscriptions(designs || {}, options)
      _update_addon_subscriptions(addon_plans || {}, options)
      site_manager.touch_timestamps(%w[loaders settings addons])
      site.save!
    end
    site_manager.delay_jobs(:loader_update, :settings_update)
  end

  # called from app/models/site.rb
  def suspend_billable_items
    site.billable_items.map(&:suspend!)
  end

  # called from app/models/site.rb
  def unsuspend_billable_items
    site.billable_items.where(state: 'suspended').each do |billable_item|
      _update_billable_item_state!(billable_item)
    end
  end

  # called from app/models/site.rb
  def cancel_billable_items
    site.billable_items.destroy_all
  end

  private

  def _build_subscription(design_or_addon, options = {})
    site.billable_items.build(item: design_or_addon, state: _new_billable_item_state(design_or_addon, options))
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
    elsif design_or_addon.free? || TrialHandler.new(site).out_of_trial?(design_or_addon)
      'subscribed'
    else
      'trial'
    end
  end

  def _update_billable_item_state!(billable_item, options = {})
    new_state = _new_billable_item_state(billable_item.item, options)
    return if new_state == billable_item.state

    billable_item.state = new_state
    billable_item.save!
  end

  def _update_or_build_subscription!(item, options = {})
    if billable_item = site.billable_items.with_item(item).first
      _update_billable_item_state!(billable_item, options)
    elsif item.not_custom? || options[:allow_custom]
      _build_subscription(item, options)
    end
  end

  def _cancel_design!(design)
    site.billable_items.with_item(design).destroy_all
  end

  def _cancel_addon!(addon, options = {})
    addon_plan_ids_to_cancel  = addon.plans.pluck(:id)
    addon_plan_ids_to_cancel -= Array(options[:except_addon_plan_ids]) if options[:except_addon_plan_ids]

    site.billable_items.addon_plans.where(item_id: addon_plan_ids_to_cancel).destroy_all
  end

  def _update_design_subscription(design_name, design_id, options = {})
    design = Design.get(design_name)

    case design_id
    when '0'
      _cancel_design!(design)
    else
      _update_or_build_subscription!(design, options)
    end
  end

  def _update_addon_subscription(addon_name, addon_plan_id, options = {})
    addon = Addon.get(addon_name)

    case addon_plan_id
    # Unsubscribe from this add-on
    when '0'
      _cancel_addon!(addon)

    # Cancel the current plan subscriptions and subscribe to the new one
    else
      addon_plan = AddonPlan.find(addon_plan_id)
      _cancel_addon!(addon, except_addon_plan_ids: addon_plan.id)
      _update_or_build_subscription!(addon_plan, options)
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

end
