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
        if site.plan_id?
          free_addon_plans_filtered = free_addon_plans(reject: %w[logo stats support])
          update_billable_addon_plans(free_addon_plans_filtered)

          case site.plan.name
          when 'plus'
            # Sponsor real-time stats
            update_billable_addon_plans({
              stats: AddonPlan.get('stats', 'realtime').id,
              support: AddonPlan.get('support', 'standard').id
            }, force: 'sponsored')
            update_billable_addon_plans({
              logo: AddonPlan.get('logo', 'disabled').id
            }, force: 'subscribed')

          when 'premium'
            # Sponsor VIP email support
            update_billable_addon_plans({
              support: AddonPlan.get('support', 'vip').id
            }, force: 'sponsored')
            update_billable_addon_plans({
              logo: AddonPlan.get('logo', 'disabled').id,
              stats: AddonPlan.get('stats', 'realtime').id
            }, force: 'subscribed')
          end
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

        set_default_app_designs(suspended: site.suspended?)
        case site.plan.name
        when 'plus'
          free_addon_plans_filtered = free_addon_plans(reject: %w[logo stats support])

          # Sponsor real-time stats
          update_billable_addon_plans(free_addon_plans_filtered)
          update_billable_addon_plans({
            stats: AddonPlan.get('stats', 'realtime').id,
            support: AddonPlan.get('support', 'standard').id
          }, force: 'sponsored', suspended: site.suspended?)
          update_billable_addon_plans({
            logo: AddonPlan.get('logo', 'disabled').id
          }, force: 'subscribed', suspended: site.suspended?)

        when 'premium'
          free_addon_plans_filtered = free_addon_plans(reject: %w[logo stats support])

          # Sponsor VIP email support
          update_billable_addon_plans(free_addon_plans_filtered, suspended: site.suspended?)
          update_billable_addon_plans({
            support: AddonPlan.get('support', 'vip').id
          }, force: 'sponsored', suspended: site.suspended?)
          update_billable_addon_plans({
            logo: AddonPlan.get('logo', 'disabled').id,
            stats: AddonPlan.get('stats', 'realtime').id
          }, force: 'subscribed', suspended: site.suspended?)

        when 'sponsored'
          # Sponsor VIP email support
          update_billable_addon_plans(free_addon_plans.merge({
            logo: AddonPlan.get('logo', 'disabled').id,
            stats: AddonPlan.get('stats', 'realtime').id,
            support: AddonPlan.get('support', 'vip').id
          }), force: 'sponsored', suspended: site.suspended?)

        else
          update_billable_addon_plans(free_addon_plans.merge({
            logo: AddonPlan.get('logo', 'sublime').id,
            stats: AddonPlan.get('stats', 'invisible').id,
            support: AddonPlan.get('support', 'standard').id
          }), suspended: site.suspended?)
        end

        site.save!
      end
    end

    private

    def new_billable_item_state(new_billable_item, options = {})
      if options[:suspended]
        'suspended'
      elsif new_billable_item.beta?
        'beta'
      elsif options[:force]
        new_billable_item.free? ? 'subscribed' : options[:force]
      else
        site.out_of_trial?(new_billable_item) || new_billable_item.free? ? 'subscribed' : 'trial'
      end
    end

    def create_default_kit
      site.kits.create(name: 'default')
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

    def free_addon_plans(options = {})
      options = { reject: [] }.merge(options)

      Addon.all.inject({}) do |hash, addon|
        if free_addon_plan = addon.free_plan
          unless free_addon_plan.availability == 'custom' || options[:reject].include?(free_addon_plan.addon.name)
            hash[addon.name.to_sym] = addon.free_plan.id
          end
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
