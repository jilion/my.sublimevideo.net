RSpec.configure do |config|
  config.before :all, addons: true do
    create_default_addons
  end
  config.before :all, plans: true do
    # create_default_plans
  end
  config.before :all, type: :request do
    create_default_addons
    # create_default_plans
  end

  config.after :all, addons: true do
    Addons::Addon.delete_all
  end
  # config.after :all, plans: true do
  #   # Plan.delete_all
  # end
  config.after :all, type: :request do
    Addons::Addon.delete_all
    # Plan.delete_all
  end
end

def create_default_addons
  @logo_addon     = create(:logo_addon)
  @stats_addon    = create(:stats_addon)
  @lightbox_addon = create(:lightbox_addon)
  @api_addon      = create(:api_addon)
  @support_addon  = create(:support_addon)

  @design_western_ap  = create(:beta_design, name: 'western', price: 495)
  @design_starwars_ap = create(:beta_design, name: 'starwars', price: 495)
  @design_twit_ap     = create(:custom_design, name: 'twit', price: 0)

  @logo_sublime_ap  = create(:addon_plan, addon: @logo_addon, name: 'sublime', price: 0)
  @logo_disabled_ap = create(:addon_plan, addon: @logo_addon, name: 'disabled', price: 995)
  @logo_custom_ap   = create(:addon_plan, addon: @logo_addon, name: 'custom', price: 1995, availability: 'beta')

  @stats_invisible_ap = create(:addon_plan, addon: @stats_addon, name: 'invisible', price: 0)
  @stats_realtime_ap  = create(:addon_plan, addon: @stats_addon, name: 'realtime', price: 995)
  @stats_disabled_ap  = create(:addon_plan, addon: @stats_addon, name: 'disabled', price: 1995)

  @lightbox_standard_ap = create(:addon_plan, addon: @lightbox_addon, name: 'standard', price: 0, availability: 'hidden')

  @api_standard_ap = create(:addon_plan, addon: @api_addon, name: 'standard', price: 0)

  @support_standard_ap = create(:addon_plan, addon: @support_addon, name: 'standard', price: 0)
  @support_vip_ap      = create(:addon_plan, addon: @support_addon, name: 'vip', price: 995)
end
