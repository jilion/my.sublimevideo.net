require_dependency 'populate'

RSpec.configure do |config|
  config.before :all, addons: true do
    create_default_addons
  end
  config.before :all, type: :request do
    create_default_addons
  end

  config.after :all, addons: true do
    App::Component.delete_all
    App::ComponentVersion.delete_all
    App::Design.delete_all
    Addon.delete_all
    AddonPlan.delete_all
    App::Plugin.delete_all
    App::SettingsTemplate.delete_all
  end
  config.after :all, type: :request do
    App::Component.delete_all
    App::ComponentVersion.delete_all
    App::Design.delete_all
    Addon.delete_all
    AddonPlan.delete_all
    App::Plugin.delete_all
    App::SettingsTemplate.delete_all
    # Plan.delete_all
  end
end

def create_default_addons
  Populate.addons
  instantiate_variables
end

def instantiate_variables
  # @app_comp = App::Component.find_by_name('app')
  @classic_design = App::Design.find_by_name('classic')
  @flat_design    = App::Design.find_by_name('flat')
  @light_design   = App::Design.find_by_name('light')
  @twit_design    = App::Design.find_by_name('twit')
  @html5_design   = App::Design.find_by_name('twit')
  @video_player_addon = Addon.find_by_name('video_player')

  @video_player_addon_plan_1 = AddonPlan.get('video_player', 'standard')
  # @video_player_addon_plan_st = create(:app_settings_template, addon_plan: @video_player_addon_plan, plugin: @video_player_addon_plugin)

  @lightbox_addon = Addon.find_by_name('lightbox')
  @lightbox_addon_plan_1 = AddonPlan.get('lightbox', 'standard')

  # @lightbox_addon_plugin_1 = create(:app_plugin, addon: @lightbox_addon, design: @classic_design, component: @app_comp)
  # @lightbox_addon_plugin_2 = create(:app_plugin, addon: @lightbox_addon, design: @light_design, component: @app_comp)
  # @lightbox_addon_plugin_3 = create(:app_plugin, addon: @lightbox_addon, design: @flat_design, component: @app_comp)

  # @lightbox_addon_plan_1_st_1 = create(:app_settings_template, addon_plan: @lightbox_addon_plan_1, plugin: @lightbox_addon_plugin_1)
  # @lightbox_addon_plan_1_st_2 = create(:app_settings_template, addon_plan: @lightbox_addon_plan_1, plugin: @lightbox_addon_plugin_2)
  # @lightbox_addon_plan_1_st_3 = create(:app_settings_template, addon_plan: @lightbox_addon_plan_1, plugin: @lightbox_addon_plugin_3)

  @image_viewer_addon = Addon.find_by_name('image_viewer')
  @image_viewer_addon_plan_1 = AddonPlan.get('image_viewer', 'standard')

  @stats_addon = Addon.find_by_name('stats')
  @stats_addon_plan_1 = AddonPlan.get('stats', 'invisible')
  @stats_addon_plan_2 = AddonPlan.get('stats', 'realtime')
  # @stats_addon_plan_3 = AddonPlan.get('stats', 'disabled')

  @logo_addon = Addon.find_by_name('logo')
  @logo_addon_plan_1    = AddonPlan.get('logo', 'sublime')
  @logo_addon_plan_2    = AddonPlan.get('logo', 'disabled')
  # @logo_addon_plan_3    = AddonPlan.get('logo', 'custom')

  # @logo_addon_plugin = App::Plugin.find_by_addon_id_and_component_id(@logo_addon.id, @app_comp.id)#create(:app_plugin, addon: @logo_addon, design: nil, component: @app_comp)
  # @logo_addon_plan_1_st = create(:app_settings_template, addon_plan: @logo_addon_plan_1, plugin: @logo_addon_plugin)
  # @logo_addon_plan_1_st = create(:app_settings_template, addon_plan: @logo_addon_plan_2, plugin: @logo_addon_plugin)
  # @logo_addon_plan_3_st = create(:app_settings_template, addon_plan: @logo_addon_plan_3, plugin: @logo_addon_plugin)

  @controls_addon = Addon.find_by_name('controls')
  @controls_addon_plan_1 = AddonPlan.get('controls', 'standard')

  @start_view_addon = Addon.find_by_name('start_view')
  @start_view_addon_plan_1 = AddonPlan.get('start_view', 'standard')

  @sharing_addon = Addon.find_by_name('sharing')
  @sharing_addon_plan_1 = AddonPlan.get('sharing', 'standard')

  @api_addon = Addon.find_by_name('api')
  @api_addon_plan_1 = AddonPlan.get('api', 'standard')

  @support_addon = Addon.find_by_name('support')
  @support_addon_plan_1 = AddonPlan.get('support', 'standard')
  @support_addon_plan_2 = AddonPlan.get('support', 'vip')

  # @support_addon_plugin = create(:app_plugin, addon: @support_addon, design: nil, component: @app_comp)
  # @support_addon_plan_1_st = create(:app_settings_template, addon_plan: @support_addon_plan_1, plugin: @support_addon_plugin)
  # @support_addon_plan_1_st = create(:app_settings_template, addon_plan: @support_addon_plan_2, plugin: @support_addon_plugin)
end
