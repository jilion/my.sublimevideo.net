require 'fast_spec_helper'
require 'rails/railtie'
require 'fog'

# for fog_mock
require 'carrierwave'
require File.expand_path('app/models/app')
require File.expand_path('config/initializers/carrierwave')
require File.expand_path('spec/config/carrierwave')
require File.expand_path('lib/s3')

require File.expand_path('lib/service/settings')

unless defined?(ActiveRecord)
  Site = Class.new
  Addon = Class.new
  AddonPlan = Class.new
  App::Component = Class.new
  App::Plugin = Class.new
  App::SettingsTemplate = Class.new
end


describe Service::Settings, :fog_mock do
  before {
    CDN.stub(:delay) { mock(purge: true) }
    site.stub_chain(:addon_plans, :includes) { [] }
  }

  let(:site) { mock("Site",
    id: 1,
    token: 'abcd1234',
    hostname: 'test.com',
    extra_hostnames: 'test.net', extra_hostnames?: true,
    dev_hostnames: 'test.dev', dev_hostnames?: true,
    wildcard: true, wildcard?: true,
    path: 'path', path?: true,
    badged: true,
    in_free_plan?: false,
    plan_stats_retention_days: 365,
    touch: true,
    accessible_stage: 'stable', player_mode: 'stable'
  )}
  let(:settings) { described_class.new(site, 'settings') }

  describe ".update_all_types!" do
    before { Site.stub(:find) { site } }

    context "site active" do
      before { site.stub(:state) { 'active' } }

      it "uploads all settings types when accessible_stage is 'beta'" do
        site.stub(:accessible_stage) { 'beta' }
        site.stub(:player_mode) { 'beta' }
        described_class.update_all_types!(site.id)
        described_class.new(site, 'license').should be_present
        described_class.new(site, 'settings').should be_present
      end

      it "uploads only license when accessible_stage is 'stable'" do
        described_class.update_all_types!(site.id)
        described_class.new(site, 'license').should be_present
        described_class.new(site, 'settings').should_not be_present
      end

      it "touches settings_updated_at" do
        site.should_receive(:touch).with(:settings_updated_at)
        described_class.update_all_types!(site.id)
      end

      it "doesn't touches settings_updated_at when touch option is false" do
        site.should_not_receive(:touch).with(:settings_updated_at)
        described_class.update_all_types!(site.id, touch: false)
      end

      context "when suspended" do
        before { site.stub(:state) { 'suspended' } }

        it "removes all settings types" do
          described_class.update_all_types!(site.id)
          described_class.new(site, 'license').should_not be_present
          described_class.new(site, 'settings').should_not be_present
        end
      end
    end
  end

  describe "file" do
    context "with license type" do
      let(:file) { described_class.new(site, 'license').file }

      it "has good content" do
        File.open(file) do |f|
          f.read.should eq "jilion.sublime.video.sites({\"h\":[\"test.com\",\"test.net\"],\"d\":[\"test.dev\"],\"w\":true,\"p\":\"path\",\"b\":true,\"s\":true,\"r\":true,\"m\":\"stable\"});\n"
        end
      end
    end

    context "with settings type" do
      let(:file) { described_class.new(site, 'settings').file }

      it "has good content" do
        File.open(file) do |f|
          f.read.should eq "settings = {\n  license: { {\"ku\":[\"test.com\",\"test.net\"],\"kv\":[\"test.dev\"],\"kz\":\"path\",\"ia\":true,\"ib\":\"stable\"} },\n  app: { {} },\n  kits: { {} },\n  defaultKit: 'default'\n}\n"
        end
      end
    end
  end

  describe "#old_license" do
    describe "common settings" do

      it "includes everything" do
        settings.old_license.should == { h: ['test.com', 'test.net'], d: ['test.dev'], w: true, p: "path", b: true, s: true, r: true, m: 'stable' }
      end

      context "without extra_hostnames" do
        before { site.stub(extra_hostnames?: false) }

        it "removes extra_hostnames from h: []" do
          settings.old_license.should == { h: ['test.com'], d: ['test.dev'], w: true, p: "path", b: true, s: true, r: true, m: 'stable' }
        end
      end

      context "without path" do
        before { site.stub(path?: false) }

        it "doesn't include path key/value" do
          settings.old_license.should == { h: ['test.com', 'test.net'], d: ['test.dev'], w: true, b: true, s: true, r: true, m: 'stable' }
        end
      end

      context "without wildcard" do
        before { site.stub(wildcard?: false) }

        it "doesn't include wildcard key/value" do
          settings.old_license.should == { h: ['test.com', 'test.net'], d: ['test.dev'], p: "path", b: true, s: true, r: true, m: 'stable' }
        end
      end

      context "without badged" do
        before { site.stub(badged: false) }

        it "includes b: false" do
          settings.old_license.should == { h: ['test.com', 'test.net'], d: ['test.dev'], w: true, p: "path", b: false, s: true, r: true, m: 'stable' }
        end
      end

      context "without ssl (free plan)" do
        before { site.stub(in_free_plan?: true) }

        it "doesn't include ssl key/value" do
          settings.old_license.should == { h: ['test.com', 'test.net'], d: ['test.dev'], w: true, p: "path", b: true, r: true, m: 'stable' }
        end
      end

      context "without realtime data (free plan)" do
        before { site.stub(plan_stats_retention_days: 0) }

        it "doesn't includes r key/value" do
          settings.old_license.should == { h: ['test.com', 'test.net'], d: ['test.dev'], w: true, p: "path", b: true, s: true, m: 'stable' }
        end
      end
    end
  end

  describe "#app_settings" do
    context "with a addon_plan with a settings_template not linked to a plugin" do
      let(:template) { {
        editable: false,
        enable: {
          values: [1],
          default: 1
        },
        realtime: {
          values: [0],
          default: 0
        }
      } }
      let(:addon) { mock(Addon) }
      let(:settings_template) { mock(App::SettingsTemplate, template: template) }
      let(:addon_plan) { mock(AddonPlan, addon: addon, settings_templates: [settings_template]) }

      before do
        settings_template.stub(:plugin?) { false }
        addon_plan.stub(:kind) { 'stats' }
        site.stub_chain(:addon_plans, :includes) { [addon_plan] }
      end

      it "includes template of this addon_plan settings_template" do
        settings.app_settings.should eq('stats' => template)
      end
    end

    context "with no addon_plans" do
      it "returns a empty hash" do
        settings.app_settings.should eq({})
      end
    end
  end

end
