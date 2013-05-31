FactoryGirl.define do

  # =============
  # = Component =
  # =============
  factory :app_component, class: App::Component do
    sequence(:token) { |n| "token#{n}" }
    sequence(:name)  { |n| "Component #{n}" }
  end

  factory :app_component_version, class: App::ComponentVersion do
    component { FactoryGirl.create(:app_component) }
    zip       { File.new(Rails.root.join('spec/fixtures/zip.zip')) }
    version   '1.0.0'
  end

  # ===========
  # = Designs =
  # ===========
  factory :design do
    component { FactoryGirl.create(:app_component) }
    sequence(:name)       { |n| "design#{n}" }
    sequence(:skin_token) { |n| "skin.token#{n}" }
    price                 495
    availability          'public'
    stable_at             { Time.now.utc }

    factory :custom_design do
      availability 'custom'
    end
  end

  # ==========
  # = Addons =
  # ==========
  factory :addon do
    sequence(:name)  { |n| "addon#{n}" }
    design_dependent true
  end

  factory :addon_plan do
    addon
    sequence(:name) { |n| "addon_plan#{n}" }
    price           995
    availability    'public'
    stable_at       Time.now.utc
  end

  factory :app_plugin, class: App::Plugin do
    addon
    design    { FactoryGirl.create(:design) }
    component { FactoryGirl.create(:app_component) }
    sequence(:token) { |n| "token#{n}" }
    sequence(:name) { |n| "name #{n}" }
  end

  factory :app_settings_template, class: App::SettingsTemplate do
    addon_plan
    plugin { FactoryGirl.create(:app_plugin) }
  end

  factory :billable_item do
    site
    state 'subscribed'
    item { FactoryGirl.create(:addon_plan) }

    factory :design_billable_item do
      item { FactoryGirl.create(:design) }
    end

    factory :addon_plan_billable_item do
      item { FactoryGirl.create(:addon_plan) }
    end
  end

  factory :billable_item_activity do
    site
    state 'subscribed'
    item { FactoryGirl.create(:addon_plan) }

    factory :design_billable_item_activity do
      item { FactoryGirl.create(:design) }
    end

    factory :addon_plan_billable_item_activity do
      item { FactoryGirl.create(:addon_plan) }
    end
  end

end
