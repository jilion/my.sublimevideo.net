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
  @logo_sublime_addon     = create(:addon, category: 'logo', name: 'sublime', price: 0)
  @logo_no_logo_addon     = create(:addon, category: 'logo', name: 'no-logo', price: 999)
  @stats_standard_addon   = create(:addon, category: 'stats', name: 'standard', price: 999)
  @support_standard_addon = create(:addon, category: 'support', name: 'standard', price: 0)
  @support_vip_addon      = create(:addon, category: 'support', name: 'vip', price: 999)
end
