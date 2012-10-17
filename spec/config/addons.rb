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

  @lightbox_addon = Addon.find_by_name('lightbox')
  @lightbox_addon_plan_1 = AddonPlan.get('lightbox', 'standard')

  @image_viewer_addon = Addon.find_by_name('image_viewer')
  @image_viewer_addon_plan_1 = AddonPlan.get('image_viewer', 'standard')

  @stats_addon = Addon.find_by_name('stats')
  @stats_addon_plan_1 = AddonPlan.get('stats', 'invisible')
  @stats_addon_plan_2 = AddonPlan.get('stats', 'realtime')
  # @stats_addon_plan_3 = AddonPlan.get('stats', 'disabled')

  @sv_logo_addon        = Addon.find_by_name('sv_logo')
  @sv_logo_addon_plan_1 = AddonPlan.get('sv_logo', 'enabled')
  @sv_logo_addon_plan_2 = AddonPlan.get('sv_logo', 'disabled')

  @controls_addon = Addon.find_by_name('controls')
  @controls_addon_plan_1 = AddonPlan.get('controls', 'standard')

  @initial_addon = Addon.find_by_name('initial')
  @initial_addon_plan_1 = AddonPlan.get('initial', 'standard')

  @sharing_addon = Addon.find_by_name('sharing')
  @sharing_addon_plan_1 = AddonPlan.get('sharing', 'standard')

  @api_addon = Addon.find_by_name('api')
  @api_addon_plan_1 = AddonPlan.get('api', 'standard')

  @support_addon = Addon.find_by_name('support')
  @support_addon_plan_1 = AddonPlan.get('support', 'standard')
  @support_addon_plan_2 = AddonPlan.get('support', 'vip')
end
