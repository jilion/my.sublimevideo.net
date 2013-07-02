require 'spec_helper'

describe SiteManager, :addons do
  let(:service) do
    s = SiteManager.new(build(:site))
    s.create
    s
  end

  describe '.suspend' do
    it 'suspends all billable items' do
      service.suspend

      service.site.reload.billable_items.should have(13).items
      service.site.billable_items.with_item(@classic_design)            .state('suspended').should have(1).item
      service.site.billable_items.with_item(@flat_design)               .state('suspended').should have(1).item
      service.site.billable_items.with_item(@light_design)              .state('suspended').should have(1).item
      service.site.billable_items.with_item(@video_player_addon_plan_1) .state('suspended').should have(1).item
      service.site.billable_items.with_item(@lightbox_addon_plan_1)     .state('suspended').should have(1).item
      service.site.billable_items.with_item(@image_viewer_addon_plan_1) .state('suspended').should have(1).item
      service.site.billable_items.with_item(@stats_addon_plan_1)        .state('suspended').should have(1).item
      service.site.billable_items.with_item(@logo_addon_plan_1)         .state('suspended').should have(1).item
      service.site.billable_items.with_item(@controls_addon_plan_1)     .state('suspended').should have(1).item
      service.site.billable_items.with_item(@initial_addon_plan_1)      .state('suspended').should have(1).item
      service.site.billable_items.with_item(@embed_addon_plan_1)        .state('suspended').should have(1).item
      service.site.billable_items.with_item(@api_addon_plan_1)          .state('suspended').should have(1).item
      service.site.billable_items.with_item(@support_addon_plan_1)      .state('suspended').should have(1).item
    end
  end

  describe '.unsuspend' do
    context 'with billable items' do
      let(:site) do
        site = build(:site)
        SiteManager.new(site).create
        site
      end

      it 'unsuspend all billable items' do
        service.suspend
        service.site.reload.billable_items.state('suspended').should have(13).item

        service.site.reload.billable_items.should have(13).items
        service.unsuspend

        service.site.reload.billable_items.should have(13).items
        service.site.billable_items.with_item(@classic_design)            .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@flat_design)               .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@light_design)              .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@video_player_addon_plan_1) .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@lightbox_addon_plan_1)     .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@image_viewer_addon_plan_1) .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@stats_addon_plan_1)        .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@logo_addon_plan_1)         .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@controls_addon_plan_1)     .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@initial_addon_plan_1)      .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@embed_addon_plan_1)        .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@api_addon_plan_1)          .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@support_addon_plan_1)      .state('subscribed').should have(1).item
      end
    end

    context 'with a billable item in trial' do
      before do
        service.update_billable_items({}, { logo: AddonPlan.get('logo', 'disabled').id })
      end

      it 'unsuspend all billable items' do
        service.site.billable_items.with_item(@logo_addon_plan_2).state('trial').should have(1).item

        service.suspend
        service.site.reload.billable_items.state('suspended').should have(13).item

        service.site.reload.billable_items.with_item(@logo_addon_plan_2).state('suspended').should have(1).item

        service.unsuspend

        service.site.reload.billable_items.should have(13).items
        service.site.billable_items.with_item(@classic_design)            .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@flat_design)               .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@light_design)              .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@video_player_addon_plan_1) .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@lightbox_addon_plan_1)     .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@image_viewer_addon_plan_1) .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@stats_addon_plan_1)        .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@logo_addon_plan_2)         .state('trial').should have(1).item
        service.site.billable_items.with_item(@controls_addon_plan_1)     .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@initial_addon_plan_1)      .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@embed_addon_plan_1)        .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@api_addon_plan_1)          .state('subscribed').should have(1).item
        service.site.billable_items.with_item(@support_addon_plan_1)      .state('subscribed').should have(1).item
      end
    end
  end

end
