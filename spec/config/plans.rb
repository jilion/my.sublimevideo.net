RSpec.configure do |config|
  config.before :all, addons: true do
    create_default_addons
  end
  config.before :all, plans: true do
    create_default_plans
  end
  config.before :all, type: :request do
    create_default_addons
    # create_default_plans
  end

  config.after :all, addons: true do
    Addons::Addon.delete_all
  end
  config.after :all, plans: true do
    Plan.delete_all
  end
  config.after :all, type: :request do
    Addons::Addon.delete_all
    # Plan.delete_all
  end
end

def create_default_plans
  @trial_plan     = create(:trial_plan)
  @free_plan      = create(:free_plan)
  @paid_plan      = create(:plan, name: "plus", video_views: 3_000)
  @sponsored_plan = create(:sponsored_plan)
  @custom_plan    = create(:custom_plan)
end

def create_default_addons
  @logo_sublime_addon     = create(:addon, category: 'logo', name: 'sublime')
  @logo_no_logo_addon     = create(:addon, category: 'logo', name: 'no-logo')
  @stats_standard_addon   = create(:addon, category: 'stats', name: 'standard')
  @support_standard_addon = create(:addon, category: 'support', name: 'standard')
  @support_vip_addon      = create(:addon, category: 'support', name: 'vip')
end
