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
    zip       { File.new(Rails.root.join('spec/fixtures/release.zip')) }
  end

  # ===========
  # = Designs =
  # ===========
  factory :app_design, class: App::Design do
    component { FactoryGirl.create(:app_component) }
    sequence(:name)       { |n| "design#{n}" }
    sequence(:skin_token) { |n| "skin.token#{n}" }
    price                 495
    availability          'public'

    factory :custom_design do
      availability 'custom'
    end
  end

  # ==========
  # = Addons =
  # ==========
  factory :addon do
    sequence(:name) { |n| "addon#{n}" }
    design_dependent true
  end

  factory :addon_plan do
    addon
    sequence(:name) { |n| "addon_plan#{n}" }
    price           995
    availability    'public'
  end

  factory :app_plugin, class: App::Plugin do
    addon
    design    { FactoryGirl.create(:app_design) }
    component { FactoryGirl.create(:app_component) }
    sequence(:token) { |n| "token#{n}" }
  end

  factory :app_settings_template, class: App::SettingsTemplate do
    addon_plan
    plugin { FactoryGirl.create(:app_plugin) }
  end

  factory :billable_item do
    site
    state 'subscribed'

    factory :design_billable_item do
      item { FactoryGirl.create(:app_design) }
    end

    factory :addon_plan_billable_item do
      item { FactoryGirl.create(:addon_plan) }
    end

    # factory :trial_addonship do
    #   state 'trial'
    #   trial_started_on { Time.now.utc.midnight }
    # end

    # factory :subscribed_addonship do
    #   state 'subscribed'
    # end

    # factory :suspended_addonship do
    #   state 'suspended'
    # end

    # factory :sponsored_addonship do
    #   state 'sponsored'
    # end

    # factory :inactive_addonship do
    #   state 'inactive'
    # end
  end

  factory :billable_item_activity do
    site

    factory :design_billable_item_activity do
      item { FactoryGirl.create(:app_design) }
    end

    factory :addon_plan_billable_item_activity do
      item { FactoryGirl.create(:addon_plan) }
    end
  end

end
