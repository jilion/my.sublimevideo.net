require_dependency 'service/rank'
require_dependency 'service/usage'

module Service
  Site = Struct.new(:site) do

    class << self

      def build(params)
        new params.delete(:user).sites.new(params)
      end

    end

    def initial_save
      ::Site.transaction do
        site.save && create_default_kit && set_default_app_designs && set_default_addon_plans && site.save && delay_set_ranks
      end
    end

    # app_designs => { "classic"=>"0", "light"=>"42" }
    # addon_plans => { "logo"=>"80", "support"=>"88" }
    def update_billable_items!(app_designs, addon_plans)
      ::Site.transaction do
        update_billable_app_designs(app_designs || {})
        update_billable_addon_plans(addon_plans || {})

        site.save!
      end
    end

    def suspend_billable_items
      ::Site.transaction do
        site.billable_items.map(&:suspend)
      end
    end

    def unsuspend_billable_items
      ::Site.transaction do
        set_default_app_designs
        if site.new_plans.present?
          site.billable_items.plans.where(item_id: site.plan.id).first.update_attribute(:state, 'subscribed')
          update_billable_addon_plans({
            logo: AddonPlan.get('logo', 'disabled').id,
            stats: AddonPlan.get('stats', 'realtime').id,
            lightbox: AddonPlan.get('lightbox', 'standard').id,
            api: AddonPlan.get('api', 'standard').id,
            support: (site.plan.name == 'premium' ? AddonPlan.get('support', 'vip') : AddonPlan.get('support', 'standard')).id
          }, sponsor: true)
        else
          site.billable_items.where(state: 'suspended').each do |billable_item|
            billable_item.update_attribute(:state, new_billable_item_state(billable_item.item))
          end
        end
      end
    end

    def update_billable_app_designs(new_app_designs, options = {})
      new_app_designs.each do |new_app_design_name, new_app_design_id|
        if new_app_design = App::Design.get(new_app_design_name)

          if new_app_design_id == '0'
            site.billable_items.app_designs.where(item_id: new_app_design.id).destroy_all
          else
            if billable_item = site.billable_items.app_designs.where(item_id: new_app_design.id).first
              billable_item.update_attribute(:state, new_billable_item_state(new_app_design, options))
            else
              site.billable_items.build({ item: new_app_design, state: new_billable_item_state(new_app_design, options) }, as: :admin)
            end
          end

        end
      end
    end

    def update_billable_addon_plans(new_addon_plans, options = {})
      new_addon_plans.each do |new_addon_name, new_addon_plan_id|
        if new_addon_plan = AddonPlan.find(new_addon_plan_id.to_i)

          site.billable_items.addon_plans.where{ item_id >> (new_addon_plan.addon.plans.pluck(:id) - [new_addon_plan.id]) }.destroy_all
          if billable_item = site.billable_items.addon_plans.where(item_id: new_addon_plan.id).first
            billable_item.update_attribute(:state, new_billable_item_state(new_addon_plan, options))
          else
            site.billable_items.build({ item: new_addon_plan, state: new_billable_item_state(new_addon_plan, options) }, as: :admin)
          end

        end
      end
    end

    def migrate_plan_to_addons!
      ::Site.transaction do
        site.billable_items.build({ item: site.plan, state: site.suspended? ? 'suspended' : 'subscribed' }, as: :admin) unless site.plan.free?

        set_default_app_designs(suspended: site.suspended?)

        advanced_plan = %w[plus premium sponsored].include?(site.plan.name)
        logo_addon_plan_name = advanced_plan ? 'disabled' : 'sublime'
        stats_addon_plan_name = advanced_plan ? 'realtime' : 'invisible'
        support_addon_plan_name = %w[premium sponsored].include?(site.plan.name) ? 'vip' : 'standard'

        update_billable_addon_plans(free_addon_plans.merge({
          logo: AddonPlan.get('logo', logo_addon_plan_name).id,
          stats: AddonPlan.get('stats', stats_addon_plan_name).id,
          support: AddonPlan.get('support', support_addon_plan_name).id
        }), sponsor: advanced_plan, suspended: site.suspended?)

        site.save!
      end
    end

    def opt_out_from_grandfather_plan!
      ::Site.transaction do
        site.billable_items.plans.where(item_id: site.plan.id).first.destroy
        update_billable_addon_plans(
          logo: AddonPlan.get('logo', 'disabled').id,
          stats: AddonPlan.get('stats', 'realtime').id,
          support: (site.plan.name == 'premium' ? AddonPlan.get('support', 'vip') : AddonPlan.get('support', 'standard')).id
        )
        site.plan_id = nil

        site.save!
      end
    end

    private

    def new_billable_item_state(new_billable_item, options = {})
      if options[:suspended]
        'suspended'
      elsif new_billable_item.beta?
        'beta'
      elsif options[:sponsor]
        new_billable_item.free? ? 'subscribed' : 'sponsored'
      else
        site.out_of_trial?(new_billable_item) || new_billable_item.free? ? 'subscribed' : 'trial'
      end
    end

    def create_default_kit
      site.kits.create(name: 'Default')
    end

    def set_default_app_designs(options = {})
      update_billable_app_designs({
        classic: App::Design.get('classic').id,
        light: App::Design.get('light').id,
        flat: App::Design.get('flat').id
      }, options)
    end

    def set_default_addon_plans
      update_billable_addon_plans(free_addon_plans)
    end

    def free_addon_plans
      Addon.all.inject({}) do |hash, addon|
        if free_addon_plan = addon.free_plan
          hash[addon.name.to_sym] = addon.free_plan.id unless free_addon_plan.availability == 'custom'
        end
        hash
      end
    end

    def delay_set_ranks
      Service::Rank.delay(priority: 100, run_at: Time.now.utc + 30).set_ranks(site.id)

      true
    end

  end
end
