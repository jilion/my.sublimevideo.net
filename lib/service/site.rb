require_dependency 'service/rank'
require_dependency 'service/usage'

module Service
  class Site

    attr_reader :site

    # One time
    def self.subscribe_site_to_embed_addon(site_id, embed_addon_id)
      new(::Site.find(site_id)).update_billable_items({}, { 'embed' => embed_addon_id })
    end

    def initialize(site)
      @site = site
    end

    def create
      ::Site.transaction do
        site.save!
        create_default_kit!

        set_default_app_designs
        set_default_addon_plans
        site.loaders_updated_at  = Time.now.utc
        site.settings_updated_at = Time.now.utc
        site.save!
      end
      LoaderGenerator.delay.update_all_stages!(site.id)
      SettingsGenerator.delay.update_all_types!(site.id)
      Service::Rank.delay(queue: 'low').set_ranks(site.id)
      Librato.increment 'sites.events', source: 'create'
      true
    rescue ::ActiveRecord::RecordInvalid
      false
    end

    def update(attributes)
      ::Site.transaction do
        site.attributes = attributes
        site.settings_updated_at = Time.now.utc
        site.save!
      end
      SettingsGenerator.delay.update_all_types!(site.id)
      Librato.increment 'sites.events', source: 'update'
      true
    rescue ::ActiveRecord::RecordInvalid
      false
    end

    # app_designs => { "classic"=>"0", "light"=>"42" }
    # addon_plans => { "logo"=>"0", "support"=>"88" }
    def update_billable_items(app_designs, addon_plans, options = {})
      ::Site.transaction do
        update_design_subscriptions(app_designs || {}, options)
        update_addon_subscriptions(addon_plans || {}, options)
        site.loaders_updated_at  = Time.now.utc
        site.settings_updated_at = Time.now.utc
        site.addons_updated_at   = Time.now.utc
        site.save!
      end
      LoaderGenerator.delay.update_all_stages!(site.id)
      SettingsGenerator.delay.update_all_types!(site.id)
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
        classic: ::App::Design.get('classic').id,
        light: ::App::Design.get('light').id,
        flat: ::App::Design.get('flat').id
      }, options)
    end

    def set_default_addon_plans
      update_addon_subscriptions(AddonPlan.free_addon_plans)
    end

    def update_design_subscriptions(design_subscriptions, options = {})
      design_subscriptions.each do |design_name, design_id|
        design = ::App::Design.get(design_name)

        case design_id
        when '0'
          cancel_design(design)
        else
          if billable_item = site.billable_items.app_designs.where(item_id: design.id).first
            update_billable_item_state!(billable_item, design, options)
          elsif design.not_custom? || options[:allow_custom]
            build_subscription(design, options)
          end
        end
      end
    end

    def update_addon_subscriptions(addon_plan_subscriptions, options = {})
      addon_plan_subscriptions.each do |addon_name, addon_plan_id|
        addon = ::Addon.get(addon_name)

        case addon_plan_id
        when '0'
          cancel_addon(addon)
        else
          addon_plan = AddonPlan.find(addon_plan_id)

          cancel_addon(addon, except_addon_plan: addon_plan)

          if billable_item = site.billable_items.addon_plans.where(item_id: addon_plan.id).first
            update_billable_item_state!(billable_item, addon_plan, options)
          elsif addon_plan.not_custom? || options[:allow_custom]
            build_subscription(addon_plan, options)
          end
        end
      end
    end

    def cancel_design(design)
      site.billable_items.app_designs.where(item_id: design.id).destroy_all
    end

    def cancel_addon(addon, options = {})
      addon_plan_ids_to_cancel  = addon.plans.pluck(:id)
      addon_plan_ids_to_cancel -= [options[:except_addon_plan].id] if options[:except_addon_plan]

      site.billable_items.addon_plans.where{ item_id >> addon_plan_ids_to_cancel }.destroy_all
    end

    def update_billable_item_state!(billable_item, item, options)
      new_state = new_billable_item_state(item, options)
      return if new_state == billable_item.state

      billable_item.state = new_state
      billable_item.save!
    end

    def build_subscription(item, options)
      site.billable_items.build({ item: item, state: new_billable_item_state(item, options) }, without_protection: true)
    end

    def new_billable_item_state(new_billable_item, options = {})
      if options[:suspended]
        'suspended'
      elsif options[:force]
        if new_billable_item.beta? || !new_billable_item.free?
          options[:force]
        else
          'subscribed'
        end
      elsif new_billable_item.beta?
        'beta'
      elsif new_billable_item.free? || site.out_of_trial?(new_billable_item)
        'subscribed'
      else
        'trial'
      end
    end
  end
end
