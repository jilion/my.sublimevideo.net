require_dependency 'service/rank'
require_dependency 'service/usage'
require_dependency 'service/loader'
require_dependency 'service/settings'

module Service
  Site = Struct.new(:site) do

    class << self
      # TODO: Remove after launch
      def migrate_plan_to_addons!(site_id, free_addon_plans, free_addon_plans_filtered)
        ::Site.find(site_id).tap do |site|
          Service::Site.new(site).migrate_plan_to_addons!(free_addon_plans, free_addon_plans_filtered)
        end
      end

      # TODO: Remove after launch
      def create_default_kit(site_id)
        ::Site.find(site_id).tap { |site| Service::Site.new(site).send(:create_default_kit!) }.save!
      end
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
      Service::Loader.delay.update_all_stages!(site.id)
      Service::Settings.delay.update_all_types!(site.id)
      Service::Rank.delay(queue: 'low').set_ranks(site.id)
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def update(attributes)
      ::Site.transaction do
        site.attributes = attributes
        site.settings_updated_at = Time.now.utc
        site.save!
      end
      Service::Settings.delay.update_all_types!(site.id)
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    # app_designs => { "classic"=>"0", "light"=>"42" }
    # addon_plans => { "logo"=>"80", "support"=>"88" }
    def update_billable_items(app_designs, addon_plans)
      ::Site.transaction do
        set_billable_app_designs(app_designs || {})
        set_billable_addon_plans(addon_plans || {})
        site.loaders_updated_at = Time.now.utc
        site.settings_updated_at = Time.now.utc
        site.save!
      end
      Service::Loader.delay.update_all_stages!(site.id)
      Service::Settings.delay.update_all_types!(site.id)
    end

    # called from app/models/site.rb
    def suspend_billable_items
      site.billable_items.map(&:suspend!)
    end

    # called from app/models/site.rb
    def unsuspend_billable_items
      set_default_app_designs
      if site.plan_id?
        set_billable_addon_plans(AddonPlan.free_addon_plans(reject: %w[logo stats support]))
        case site.plan.name
        when 'plus'
          # Sponsor real-time stats
          set_billable_addon_plans({
            stats: AddonPlan.get('stats', 'realtime').id,
            support: AddonPlan.get('support', 'standard').id
          }, force: 'sponsored')
          set_billable_addon_plans({
            logo: AddonPlan.get('logo', 'disabled').id
          }, force: 'subscribed')
        when 'premium'
          # Sponsor VIP email support
          set_billable_addon_plans({
            support: AddonPlan.get('support', 'vip').id
          }, force: 'sponsored')
          set_billable_addon_plans({
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

    # TODO: Remove after launch
    def migrate_plan_to_addons!(free_addon_plans, free_addon_plans_filtered)
      ::Site.transaction do
        set_default_app_designs(force: site.plan.try(:name) == 'sponsored' ? 'sponsored' : nil, suspended: site.suspended?)
        case site.plan.try(:name)
        when 'plus'
          # Sponsor real-time stats
          set_billable_addon_plans(free_addon_plans_filtered)
          set_billable_addon_plans({
            stats: AddonPlan.get('stats', 'realtime').id,
            support: AddonPlan.get('support', 'standard').id
          }, force: 'sponsored', suspended: site.suspended?)
          set_billable_addon_plans({
            logo: AddonPlan.get('logo', 'disabled').id
          }, force: 'subscribed', suspended: site.suspended?)
        when 'premium'
          # Sponsor VIP email support
          set_billable_addon_plans(free_addon_plans_filtered, suspended: site.suspended?)
          set_billable_addon_plans({
            support: AddonPlan.get('support', 'vip').id
          }, force: 'sponsored', suspended: site.suspended?)
          set_billable_addon_plans({
            logo: AddonPlan.get('logo', 'disabled').id,
            stats: AddonPlan.get('stats', 'realtime').id
          }, force: 'subscribed', suspended: site.suspended?)
        when 'sponsored'
          # Sponsor VIP email support
          set_billable_addon_plans(free_addon_plans.merge({
            logo: AddonPlan.get('logo', 'disabled').id,
            stats: AddonPlan.get('stats', 'realtime').id,
            support: AddonPlan.get('support', 'vip').id
          }), force: 'sponsored', suspended: site.suspended?)
        else
          set_billable_addon_plans(free_addon_plans.merge({
            logo: AddonPlan.get('logo', 'sublime').id,
            stats: AddonPlan.get('stats', 'invisible').id,
            support: AddonPlan.get('support', 'standard').id
          }), suspended: site.suspended?)
        end
        site.save!
      end
    end

    private

    def create_default_kit!
      site.kits.create!
      site.default_kit = site.kits.first
    end

    def set_default_app_designs(options = {})
      set_billable_app_designs({
        classic: ::App::Design.get('classic').id,
        light: ::App::Design.get('light').id,
        flat: ::App::Design.get('flat').id
      }, options)
    end

    def set_billable_app_designs(new_app_designs, options = {})
      new_app_designs.each do |new_app_design_name, new_app_design_id|
        if new_app_design = ::App::Design.get(new_app_design_name)
          if new_app_design_id == '0'
            site.billable_items.app_designs.where(item_id: new_app_design.id).destroy_all
          else
            if billable_item = site.billable_items.app_designs.where(item_id: new_app_design.id).first
              billable_item.state = new_billable_item_state(new_app_design, options)
              billable_item.save!
            else
              site.billable_items.build({ item: new_app_design, state: new_billable_item_state(new_app_design, options) }, as: :admin)
            end
          end
        end
      end
    end

    def set_default_addon_plans
      set_billable_addon_plans(AddonPlan.free_addon_plans)
    end

    def set_billable_addon_plans(new_addon_plans, options = {})
      new_addon_plans.each do |new_addon_name, new_addon_plan_id|
        if new_addon_plan = AddonPlan.find(new_addon_plan_id.to_i)
          site.billable_items.addon_plans.where{ item_id >> (new_addon_plan.addon.plans.pluck(:id) - [new_addon_plan.id]) }.destroy_all
          if billable_item = site.billable_items.addon_plans.where(item_id: new_addon_plan.id).first
            billable_item.state = new_billable_item_state(new_addon_plan, options)
            billable_item.save!
          else
            site.billable_items.build({ item: new_addon_plan, state: new_billable_item_state(new_addon_plan, options) }, as: :admin)
          end
        end
      end
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
