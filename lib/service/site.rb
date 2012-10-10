require_dependency 'service/rank'
require_dependency 'service/usage'

module Service
  Site = Struct.new(:site) do

    class << self

      def build_site(params)
        new params.delete(:user).sites.new(params)
      end

    end

    def initial_save
      ::Site.transaction do
        site.save && set_default_app_designs && set_default_addon_plans && site.save && delay_set_ranks
      end
    end

    # app_designs => { "classic"=>"0", "light"=>"42" }
    # addon_plans => { "logo"=>"80", "support"=>"88" }
    def update_billable_items!(app_designs = {}, addon_plans = {})
      ::Site.transaction do
        update_billable_app_designs(app_designs)
        update_billable_addon_plans(addon_plans)

        site.save!
      end
    end

    def update_billable_app_designs(new_app_designs)
      new_app_designs.each do |new_app_design_name, new_app_design_id|
        if new_app_design = App::Design.get(new_app_design_name)

          if new_app_design_id == '0'
            site.billable_items.app_designs.where(item_id: new_app_design.id).destroy_all
          else
            if billable_item = site.billable_items.app_designs.where(item_id: new_app_design.id).first
              billable_item.update_attribute(:state, new_billable_item_state(new_app_design))
            else
              site.billable_items.build({ item: new_app_design, state: new_billable_item_state(new_app_design) }, as: :admin)
            end
          end

        end
      end
    end

    def update_billable_addon_plans(new_addon_plans)
      new_addon_plans.each do |new_addon_name, new_addon_plan_id|
        if new_addon_plan = AddonPlan.find(new_addon_plan_id.to_i)

          site.billable_items.addon_plans.where{ item_id >> (new_addon_plan.addon.plans.pluck(:id) - [new_addon_plan.id]) }.destroy_all
          if billable_item = site.billable_items.addon_plans.where(item_id: new_addon_plan.id).first
            billable_item.update_attribute(:state, new_billable_item_state(new_addon_plan))
          else
            site.billable_items.build({ item: new_addon_plan, state: new_billable_item_state(new_addon_plan) }, as: :admin)
          end

        end
      end
    end

    def migrate_plan_to_addons
      ::Site.transaction do
        site.billable_items.build({ item: site.plan, state: 'subscribed' }, as: :admin)
        set_default_app_designs
        site.billable_items.build({ item: AddonPlan.get('logo', 'disabled'), state: 'sponsored' }, as: :admin)
        site.billable_items.build({ item: AddonPlan.get('stats', 'realtime'), state: 'sponsored' }, as: :admin)
        site.billable_items.build({ item: AddonPlan.get('lightbox', 'standard'), state: 'subscribed' }, as: :admin)
        site.billable_items.build({ item: AddonPlan.get('api', 'standard'), state: 'subscribed' }, as: :admin)
        if site.plan.name == 'premium'
          site.billable_items.build({ item: AddonPlan.get('support', 'vip'), state: 'sponsored' }, as: :admin)
        else
          site.billable_items.build({ item: AddonPlan.get('support', 'standard'), state: 'subscribed' }, as: :admin)
        end

        site.save
      end
    end

    def opt_out_from_grandfather_plan
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

    def new_billable_item_state(new_billable_item)
      if new_billable_item.beta?
        'beta'
      else
        site.out_of_trial?(new_billable_item) || new_billable_item.free? ? 'subscribed' : 'trial'
      end
    end

    def set_default_app_designs
      update_billable_app_designs(
        classic: App::Design.get('classic').id,
        light: App::Design.get('light').id,
        flat: App::Design.get('flat').id
      )
    end

    def set_default_addon_plans
      update_billable_addon_plans(
        logo: AddonPlan.get('logo', 'sublime').id,
        stats: AddonPlan.get('stats', 'invisible').id,
        lightbox: AddonPlan.get('lightbox', 'standard').id,
        api: AddonPlan.get('api', 'standard').id,
        support: AddonPlan.get('support', 'standard').id
      )
    end

    def delay_set_ranks
      Service::Rank.delay(priority: 100, run_at: Time.now.utc + 30).set_ranks(site.id)

      true
    end

  end
end
