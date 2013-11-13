require 'fast_spec_helper'

require 'services/user_support_manager'

Addons = Module.new unless defined?(Addons)
AddonPlan = Class.new unless defined?(AddonPlan)

describe UserSupportManager do
  let(:user)    { Struct.new(:id).new(1234) }
  let(:site)    { Struct.new(:user, :id).new(user, 1234) }
  let(:manager) { described_class.new(user) }
  let(:addon)   { double.as_null_object }

  describe '#level' do
    before do
      expect(AddonPlan).to receive(:get).with('support', 'vip') { addon }
      user.stub_chain(:sites, :not_archived) { [site] }
    end

    it 'returns nil if site dont have the VIP email support add-on active & not subscribed (or trial) to any paid add-on' do
      expect(site).to receive(:subscribed_to?).with(addon) { false }
      expect(site).to receive(:sponsored_to?).with(addon) { false }
      expect(user).to receive(:trial_or_billable?) { false }
      expect(user).to receive(:sponsored?) { false }

      expect(manager.level).to be_nil
    end

    it 'returns email if site dont have the VIP email support add-on active, not subscribed (or trial) to any paid add-on but sponsored' do
      expect(site).to receive(:subscribed_to?).with(addon) { false }
      expect(site).to receive(:sponsored_to?).with(addon) { false }
      expect(user).to receive(:trial_or_billable?) { false }
      expect(user).to receive(:sponsored?) { true }

      expect(manager.level).to eq 'email'
    end

    it 'returns email if site dont have the VIP email support add-on active but subscribed (or trial) to a paid add-on' do
      expect(site).to receive(:subscribed_to?).with(addon) { false }
      expect(site).to receive(:sponsored_to?).with(addon) { false }
      expect(user).to receive(:trial_or_billable?) { true }

      expect(manager.level).to eq 'email'
    end

    it 'returns vip_email if site has the VIP email support add-on active' do
      expect(site).to receive(:subscribed_to?).with(addon) { true }

      expect(manager.level).to eq 'vip_email'
    end

    it 'returns vip_email if site has the VIP email support add-on active' do
      expect(site).to receive(:subscribed_to?).with(addon) { false }
      expect(site).to receive(:sponsored_to?) { true }

      expect(manager.level).to eq 'vip_email'
    end
  end

end
