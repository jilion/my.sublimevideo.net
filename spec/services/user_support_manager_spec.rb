require 'fast_spec_helper'

require 'services/user_support_manager'

describe UserSupportManager do
  let(:user)             { Struct.new(:id).new(1234) }
  let(:site)             { Struct.new(:user, :id).new(user, 1234) }
  let(:manager)          { described_class.new(user) }
  let(:vip_addon)        { stub.as_null_object }
  let(:enterprise_addon) { stub.as_null_object }

  describe '#email_support?' do
    context 'level is email' do
      before { manager.stub(:level) { 'email' } }

      it 'returns true' do
        manager.should be_email_support
      end
    end

    context 'level is vip_email' do
      before { manager.stub(:level) { 'vip_email' } }

      it 'returns true' do
        manager.should be_email_support
      end
    end

    context 'level is enterprise_email' do
      before { manager.stub(:level) { 'enterprise_email' } }

      it 'returns true' do
        manager.should be_email_support
      end
    end
  end

  describe '#vip_email_support?' do
    context 'level is email' do
      before { manager.stub(:level) { 'email' } }

      it 'returns false' do
        manager.should_not be_vip_email_support
      end
    end

    context 'level is vip_email' do
      before { manager.stub(:level) { 'vip_email' } }

      it 'returns true' do
        manager.should be_vip_email_support
      end
    end

    context 'level is enterprise_email' do
      before { manager.stub(:level) { 'enterprise_email' } }

      it 'returns false' do
        manager.should_not be_vip_email_support
      end
    end
  end

  describe '#enterprise_email_support?' do
    context 'level is email' do
      before { manager.stub(:level) { 'email' } }

      it 'returns false' do
        manager.should_not be_enterprise_email_support
      end
    end

    context 'level is vip_email' do
      before { manager.stub(:level) { 'vip_email' } }

      it 'returns false' do
        manager.should_not be_enterprise_email_support
      end
    end

    context 'level is enterprise_email' do
      before { manager.stub(:level) { 'enterprise_email' } }

      it 'returns true' do
        manager.should be_enterprise_email_support
      end
    end
  end

  describe '#level' do
    before do
      manager.stub(:_get_addon_plan).with('vip') { vip_addon }
      manager.stub(:_get_addon_plan).with('enterprise') { enterprise_addon }
      user.stub_chain(:sites, :not_archived) { [site] }
    end

    context 'site dont have the VIP/Enterprise email support add-on active' do
      before do
        site.should_receive(:subscribed_to?).with(vip_addon) { false }
        site.should_receive(:sponsored_to?).with(vip_addon) { false }
        site.should_receive(:subscribed_to?).with(enterprise_addon) { false }
        site.should_receive(:sponsored_to?).with(enterprise_addon) { false }
      end

      it 'returns nil if not subscribed (or trial) to any paid add-on' do
        user.should_receive(:trial_or_billable?) { false }
        user.should_receive(:sponsored?) { false }

        manager.level.should be_nil
      end

      it 'returns email if not subscribed (or trial) to any paid add-on but sponsored' do
        user.should_receive(:trial_or_billable?) { false }
        user.should_receive(:sponsored?) { true }

        manager.level.should eq 'email'
      end

      it 'returns email if subscribed (or trial) to a paid add-on' do
        user.should_receive(:trial_or_billable?) { true }

        manager.level.should eq 'email'
      end
    end

    context 'site has the VIP email support add-on active' do
      it 'returns enterprise_email when VIP email support add-on is subscribed' do
        site.should_receive(:subscribed_to?).with(vip_addon) { true }

        manager.level.should eq 'vip_email'
      end

      it 'returns enterprise_email when VIP email support add-on is sponsored' do
        site.should_receive(:subscribed_to?).with(vip_addon) { false }
        site.should_receive(:sponsored_to?).with(vip_addon) { true }

        manager.level.should eq 'vip_email'
      end
    end

    context 'site has the Enterprise email support add-on active' do
      before do
        site.should_receive(:subscribed_to?).with(vip_addon) { false }
        site.should_receive(:sponsored_to?).with(vip_addon) { false }
      end

      it 'returns enterprise_email when Enterprise email support add-on is subscribed' do
        site.should_receive(:subscribed_to?).with(enterprise_addon) { true }

        manager.level.should eq 'enterprise_email'
      end

      it 'returns enterprise_email when Enterprise email support add-on is sponsored' do
        site.should_receive(:subscribed_to?).with(enterprise_addon) { false }
        site.should_receive(:sponsored_to?).with(enterprise_addon) { true }

        manager.level.should eq 'enterprise_email'
      end
    end
  end

  describe '#guaranteed_response_time' do
    context 'level is email' do
      before { manager.stub(:level) { 'email' } }

      it 'returns true' do
        manager.guaranteed_response_time.should eq 3600 * 24 * 5
      end
    end

    context 'level is vip_email' do
      before { manager.stub(:level) { 'vip_email' } }

      it 'returns true' do
        manager.guaranteed_response_time.should eq 3600 * 24
      end
    end

    context 'level is enterprise_email' do
      before { manager.stub(:level) { 'enterprise_email' } }

      it 'returns true' do
        manager.guaranteed_response_time.should eq 3600
      end
    end
  end

end
