require 'fast_spec_helper'
require File.expand_path('lib/users/support_manager')

Addons = Module.new unless defined?(Addons)
Addons::Addon = Class.new unless defined?(Addons::Addon)

describe Users::SupportManager do
  let(:user)    { Struct.new(:id).new(1234) }
  let(:site)    { Struct.new(:user, :id).new(user, 1234) }
  let(:manager) { described_class.new(user) }
  let(:addon)   { stub.as_null_object }

  describe '#level' do
    before do
      Addons::Addon.should_receive(:get).with('support', 'vip') { addon }
      user.stub_chain(:sites, :not_archived) { [site] }
    end

    it 'returns email if site dont have the VIP email support add-on active' do
      site.should_receive(:addon_is_active?).with(addon) { false }

      manager.level.should eq 'email'
    end

    it 'returns vip_email if site has the VIP email support add-on active' do
      site.should_receive(:addon_is_active?).with(addon) { true }

      manager.level.should eq 'vip_email'
    end
  end

end
