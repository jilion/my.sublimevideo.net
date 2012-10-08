require_dependency 'service/rank'
require_dependency 'service/usage'

module Service
  Site = Struct.new(:site) do

    class << self

      def build_site(params)
        new params.delete(:user).sites.new(params)
      end

      def activate_addonships_out_of_trial!
        ::Site.with_out_of_trial_addons.find_each(batch_size: 100) do |site|
          delay.activate_addonships_out_of_trial_for_site!(site.id)
        end
      end

      def activate_addonships_out_of_trial_for_site!(site_id)
        site = Site.find(site_id)

        ::Site.transaction do
          site.addons.out_of_trial.each do |addon|
            new(site).activate_addonship!(addon)
          end
        end
      end

    end

    def save
      ::Site.transaction do
        site.save && set_default_app_designs && set_default_addon_plans && site.save && delay_set_ranks
      end
    end

    # app_designs => { "classic"=>"0", "light"=>"42" }
    # addon_plans => { "logo"=>"80", "support"=>"88" }
    def update_billable_items!(app_designs, addon_plans)
      app_designs ||= []
      addon_plans ||= []

      ::Site.transaction do
        update_billable_app_designs(app_designs || [])
        update_billable_addon_plans(addon_plans || [])

        site.save!
      end
    end

    def update_billable_app_designs(new_app_designs)
      new_app_designs.each do |new_app_design_name, new_app_design_id|
        if new_app_design = App::Design.get(new_app_design_name)
          next if site.app_design_is_active?(new_app_design)

          if new_app_design_id == '0'
            # puts "Deactivate #{new_app_design.inspect}"
            site.billable_items.where(item: new_app_design).destroy
          else
            # puts "Activate #{new_app_design.inspect}"
            site.billable_items.build({ item: new_app_design, state: new_billable_item_state(new_app_design) }, as: :admin)
          end
        end
      end
    end

    def update_billable_addon_plans(new_addon_plans)
      new_addon_plans.each do |new_addon_name, new_addon_plan_id|
        if new_addon_plan = AddonPlan.find(new_addon_plan_id)
          next if site.addon_plan_is_active?(new_addon_plan)

          site.billable_items.addon_plans.where{ item_id >> new_addon_plan.addon.plans }.destroy_all
          # puts "Activate #{new_addon_plan.inspect}"
          site.billable_items.build({ item: new_addon_plan, state: new_billable_item_state(new_addon_plan) }, as: :admin)
        end
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
      site.billable_items.build({ item: App::Design.get('classic'), state: 'subscribed' }, as: :admin)
      site.billable_items.build({ item: App::Design.get('light'), state: 'subscribed' }, as: :admin)
      site.billable_items.build({ item: App::Design.get('flat'), state: 'subscribed' }, as: :admin)
    end

    def set_default_addon_plans
      site.billable_items.build({ item: AddonPlan.get('logo', 'sublime'), state: 'subscribed' }, as: :admin)
      site.billable_items.build({ item: AddonPlan.get('stats', 'invisible'), state: 'subscribed' }, as: :admin)
      site.billable_items.build({ item: AddonPlan.get('lightbox', 'standard'), state: 'subscribed' }, as: :admin)
      site.billable_items.build({ item: AddonPlan.get('api', 'standard'), state: 'subscribed' }, as: :admin)
      site.billable_items.build({ item: AddonPlan.get('support', 'standard'), state: 'subscribed' }, as: :admin)
    end

    def delay_set_ranks
      Service::Rank.delay(priority: 100, run_at: Time.now.utc + 30).set_ranks(site.id)

      true
    end

  end
end
