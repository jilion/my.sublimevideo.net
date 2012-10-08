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
    App::Component.delete_all
    App::Design.delete_all
    Addon.delete_all
    AddonPlan.delete_all
    App::Plugin.delete_all
    App::SettingsTemplate.delete_all
  end
  # config.after :all, plans: true do
  #   # Plan.delete_all
  # end
  config.after :all, type: :request do
    App::Component.delete_all
    App::Design.delete_all
    Addon.delete_all
    AddonPlan.delete_all
    App::Plugin.delete_all
    App::SettingsTemplate.delete_all
    # Plan.delete_all
  end
end

def create_default_addons
  create_components
  create_designs
  create_video_player_addon
  create_logo_addon
  create_stats_addon
  create_lightbox_addon
  create_api_addon
  create_support_addon
end

def create_components
  @app_comp = create(:app_component, name: 'sublime', token: 'a')
  create(:app_component_version, component: @app_comp, version: '2.0.0-alpha')
end

def create_designs
  @classic_design = create(:app_design, name: 'classic', price: 495, component: @app_comp)
  @light_design   = create(:app_design, name: 'light', price: 495, component: @app_comp)
  @flat_design    = create(:app_design, name: 'flat', price: 495, component: @app_comp)
  @twit_design    = create(:app_design, name: 'twit', price: 0, availability: 'custom', component: @app_comp)
end

def create_video_player_addon
  @video_player_addon = create(:addon, name: 'video_player', design_dependent: false, context: ['videoPlayer'])

  @video_player_addon_plugin = create(:app_plugin, addon: @video_player_addon, design: nil, component: @app_comp)

  @video_player_addon_plan    = create(:addon_plan, name: 'standard', price: 0, addon: @video_player_addon, availability: 'hidden')
  @video_player_addon_plan_st = create(:app_settings_template, addon_plan: @video_player_addon_plan, plugin: @video_player_addon_plugin)
end

def create_logo_addon
  @logo_addon = create(:addon, name: 'logo', design_dependent: false, context: ['videoPlayer', 'badge'])

  @logo_addon_plugin = create(:app_plugin, addon: @logo_addon, design: nil, component: @app_comp)

  @logo_addon_plan_1    = create(:addon_plan, name: 'sublime', price: 0, addon: @logo_addon)
  @logo_addon_plan_1_st = create(:app_settings_template, addon_plan: @logo_addon_plan_1, plugin: @logo_addon_plugin)

  @logo_addon_plan_2    = create(:addon_plan, name: 'disabled', price: 995, addon: @logo_addon)
  @logo_addon_plan_1_st = create(:app_settings_template, addon_plan: @logo_addon_plan_2, plugin: @logo_addon_plugin)

  @logo_addon_plan_3    = create(:addon_plan, name: 'custom', price: 1995, addon: @logo_addon, works_with_stable_app: false)
  @logo_addon_plan_3_st = create(:app_settings_template, addon_plan: @logo_addon_plan_3, plugin: @logo_addon_plugin)
end

def create_stats_addon
  @stats_addon = create(:addon, name: 'stats', design_dependent: false, context: ['videoPlayer', 'stats'])

  @stats_addon_plugin = create(:app_plugin, addon: @stats_addon, design: nil, component: @app_comp)

  @stats_addon_plan_1    = create(:addon_plan, name: 'invisible', price: 0, addon: @stats_addon, availability: 'hidden')
  @stats_addon_plan_1_st = create(:app_settings_template, addon_plan: @stats_addon_plan_1, plugin: @stats_addon_plugin)

  @stats_addon_plan_2    = create(:addon_plan, name: 'realtime', price: 995, addon: @stats_addon)
  @stats_addon_plan_2_st = create(:app_settings_template, addon_plan: @stats_addon_plan_2, plugin: @stats_addon_plugin)

  @stats_addon_plan_3    = create(:addon_plan, name: 'disabled', price: 1995, addon: @stats_addon, availability: 'hidden', works_with_stable_app: false)
  @stats_addon_plan_3_st = create(:app_settings_template, addon_plan: @stats_addon_plan_3, plugin: @stats_addon_plugin)
end

def create_lightbox_addon
  @lightbox_addon = create(:addon, name: 'lightbox', design_dependent: true, context: ['lightbox'])

  @lightbox_addon_plugin_1 = create(:app_plugin, addon: @lightbox_addon, design: @classic_design, component: @app_comp)
  @lightbox_addon_plugin_2 = create(:app_plugin, addon: @lightbox_addon, design: @light_design, component: @app_comp)
  @lightbox_addon_plugin_3 = create(:app_plugin, addon: @lightbox_addon, design: @flat_design, component: @app_comp)

  @lightbox_addon_plan_1      = create(:addon_plan, name: 'standard', price: 0, addon: @lightbox_addon)
  @lightbox_addon_plan_1_st_1 = create(:app_settings_template, addon_plan: @lightbox_addon_plan_1, plugin: @lightbox_addon_plugin_1)
  @lightbox_addon_plan_1_st_2 = create(:app_settings_template, addon_plan: @lightbox_addon_plan_1, plugin: @lightbox_addon_plugin_2)
  @lightbox_addon_plan_1_st_3 = create(:app_settings_template, addon_plan: @lightbox_addon_plan_1, plugin: @lightbox_addon_plugin_3)
end

def create_api_addon
  @api_addon = create(:addon, name: 'api', design_dependent: false)

  @api_addon_plugin = create(:app_plugin, addon: @api_addon, design: nil, component: @app_comp)

  @api_addon_plan    = create(:addon_plan, name: 'standard', price: 0, addon: @api_addon)
  @api_addon_plan_st = create(:app_settings_template, addon_plan: @api_addon_plan, plugin: @api_addon_plugin)
end

def create_support_addon
  @support_addon = create(:addon, name: 'support', design_dependent: false)

  @support_addon_plugin = create(:app_plugin, addon: @support_addon, design: nil, component: @app_comp)

  @support_addon_plan_1    = create(:addon_plan, name: 'standard', price: 0, addon: @support_addon)
  @support_addon_plan_1_st = create(:app_settings_template, addon_plan: @support_addon_plan_1, plugin: @support_addon_plugin)

  @support_addon_plan_2    = create(:addon_plan, name: 'vip', price: 9995, addon: @support_addon)
  @support_addon_plan_1_st = create(:app_settings_template, addon_plan: @support_addon_plan_2, plugin: @support_addon_plugin)
end
