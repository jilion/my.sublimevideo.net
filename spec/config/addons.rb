require 'populate'

RSpec.configure do |config|
  config.before :all, addons: true do
    create_default_addons
  end
  config.before :all, type: :feature do
    create_default_addons
  end

  config.after :all, addons: true do
    clear_default_addons
  end
  config.after :all, type: :feature do
    clear_default_addons
  end
end

def create_default_addons
  Populate.addons
  instantiate_variables
end

def clear_default_addons
  App::Component.delete_all
  App::ComponentVersion.delete_all
  App::Design.delete_all
  Addon.delete_all
  AddonPlan.delete_all
  App::Plugin.delete_all
  App::SettingsTemplate.delete_all
end

def instantiate_variables
  @classic_design = App::Design.get('classic')
  @flat_design    = App::Design.get('flat')
  @light_design   = App::Design.get('light')
  @twit_design    = App::Design.get('twit')
  @html5_design   = App::Design.get('html5')

  @video_player_addon = Addon.get('video_player')
  @video_player_addon_plan_1 = AddonPlan.get('video_player', 'standard')

  @lightbox_addon = Addon.get('lightbox')
  @lightbox_addon_plan_1 = AddonPlan.get('lightbox', 'standard')

  @image_viewer_addon = Addon.get('image_viewer')
  @image_viewer_addon_plan_1 = AddonPlan.get('image_viewer', 'standard')

  @stats_addon = Addon.get('stats')
  @stats_addon_plan_1 = AddonPlan.get('stats', 'invisible')
  @stats_addon_plan_2 = AddonPlan.get('stats', 'realtime')

  @logo_addon        = Addon.get('logo')
  @logo_addon_plan_1 = AddonPlan.get('logo', 'sublime')
  @logo_addon_plan_2 = AddonPlan.get('logo', 'disabled')
  @logo_addon_plan_3 = AddonPlan.get('logo', 'custom')

  @controls_addon        = Addon.get('controls')
  @controls_addon_plan_1 = AddonPlan.get('controls', 'standard')

  @initial_addon        = Addon.get('initial')
  @initial_addon_plan_1 = AddonPlan.get('initial', 'standard')

  @social_sharing_addon        = Addon.get('social_sharing')
  @social_sharing_addon_plan_1 = AddonPlan.get('social_sharing', 'standard')

  @embed_addon        = Addon.get('embed')
  @embed_addon_plan_1 = AddonPlan.get('embed', 'manual')
  @embed_addon_plan_2 = AddonPlan.get('embed', 'auto')

  @api_addon        = Addon.get('api')
  @api_addon_plan_1 = AddonPlan.get('api', 'standard')

  @support_addon        = Addon.get('support')
  @support_addon_plan_1 = AddonPlan.get('support', 'standard')
  @support_addon_plan_2 = AddonPlan.get('support', 'vip')
  @support_addon_plan_3 = AddonPlan.get('support', 'enterprise')
end
