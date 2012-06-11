RSpec.configure do |config|
  config.before :all, plans: true do
    create_default_plans
  end
  config.before :all, type: :request do
    create_default_plans
  end

  config.after :all, plans: true do
    Plan.delete_all
  end
  config.after :all, type: :request do
    Plan.delete_all
  end
end

def create_default_plans
  @free_plan      = create(:free_plan, support_level: 0)
  @paid_plan      = create(:plan, name: "plus", video_views: 3_000, support_level: 1)
  @sponsored_plan = create(:sponsored_plan, support_level: 2)
  @custom_plan    = create(:custom_plan, support_level: 2)
end
