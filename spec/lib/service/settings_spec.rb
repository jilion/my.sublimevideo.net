require 'fast_spec_helper'
require 'rails/railtie'
require 'fog'

require 'sidekiq'
require File.expand_path('spec/config/sidekiq')
require File.expand_path('spec/support/sidekiq_custom_matchers')

# for fog_mock
require 'carrierwave'
require File.expand_path('app/models/app')
require File.expand_path('config/initializers/carrierwave')
require File.expand_path('spec/config/carrierwave')
require 's3'

require 'service/settings'

unless defined?(ActiveRecord)
  Site = Class.new
  Addon = Class.new
  AddonPlan = Class.new
  Kit = Class.new
  App::Design = Class.new
  App::Component = Class.new
  App::Plugin = Class.new
  App::SettingsTemplate = Class.new
end


describe Service::Settings, :fog_mock do
  before do
    site.stub_chain(:addon_plans, :includes, :order) { [] }
    site.stub_chain(:kits, :includes, :order) { [] }
    AddonPlan.stub(:get)
  end

  let(:site) { mock("Site",
    id: 1,
    token: 'abcd1234',
    hostname: 'test.com',
    extra_hostnames: 'test.net', extra_hostnames?: true,
    dev_hostnames: 'test.dev', dev_hostnames?: true,
    wildcard: true, wildcard?: true,
    path: 'path', path?: true,
    badged: true,
    addon_plan_is_active?: true,
    accessible_stage: 'stable', player_mode: 'stable',
    default_kit: stub(identifier: '1')
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

      it "uploads all settings types when accessible_stage is 'stable'" do
        described_class.update_all_types!(site.id)
        described_class.new(site, 'license').should be_present
        described_class.new(site, 'settings').should be_present
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
          f.read.should eq "sublime_.jd(\"ko\",[],function(){var a;return a={kr:{\"ku\":[\"test.com\",\"test.net\"],\"kv\":[\"test.dev\"],\"kz\":\"path\",\"ia\":true,\"ib\":\"stable\"},sa:{},ks:{},kt:'1'},[a]})\n"
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

      context "without realtime addons" do
        before { site.stub(addon_plan_is_active?: false) }

        it "doesn't includes r key/value" do
          settings.old_license.should == { h: ['test.com', 'test.net'], d: ['test.dev'], w: true, p: "path", b: true, s: true, m: 'stable' }
        end
      end
    end
  end

  describe "#app_settings" do
    context "with a addon_plan with a settings_template not linked to a plugin" do
      let(:template) { {
        enabled: {
          type: 'boolean',
          values: [true],
          default: true
        },
        realtime: {
          type: 'boolean',
          values: [false],
          default: false
        }
      } }
      let(:addon) { mock(Addon) }
      let(:settings_template) { mock(App::SettingsTemplate, template: template, plugin: nil) }
      let(:addon_plan) { mock(AddonPlan, addon: addon, settings_templates: [settings_template], kind: 'stats') }

      before do
        site.stub_chain(:addon_plans, :includes, :order) { [addon_plan] }
      end

      it "includes template of this addon_plan settings_template" do
        settings.app_settings.should eq({
          'stats' => {
            settings: {
              enabled: true,
              realtime: false
            },
            allowed_settings: {
              enabled: {
                values: [true]
              },
              realtime: {
                values: [false]
              }
            }
          }
        })
      end
    end

    context "with no addon_plans" do
      it "returns a empty hash" do
        settings.app_settings.should eq({})
      end
    end
  end

  describe "#kits" do
    context "with a addon_plan with a settings_template not linked to a plugin" do
      let(:template1) { {
        autoplay: {
          type: 'boolean',
          values: [true, false],
          default: true
        }
      } }
      let(:template2_1) { {
        close_button_position: {
          type: 'string',
          values: ['left', 'right'],
          default: 'left'
        }
      } }
      let(:template2_2) { {
        close_button_position: {
          type: 'string',
          values: ['left', 'right'],
          default: 'right'
        }
      } }
      let(:kit_settings1) { {
        'addon1' => { autoplay: false },
        'addon2' => { close_button_position: 'right' }
      } }
      let(:kit_settings2) { {
        'addon2' => { close_button_position: 'left' }
      } }
      let(:kit1) { mock(Kit, identifier: '1', app_design_id: 1, skin_token: 'skin_token1', settings: kit_settings1) }
      let(:kit2) { mock(Kit, identifier: '2', app_design_id: 2, skin_token: 'skin_token2', settings: kit_settings2) }
      let(:addon1) { mock(Addon, id: 1, name: 'addon1', parent_addon_id: nil) }
      let(:addon2) { mock(Addon, id: 2, name: 'addon2', parent_addon_id: addon1.id) }
      let(:addon3) { mock(Addon, id: 3, name: 'addon3', parent_addon_id: nil) }
      let(:plugin1) { mock(App::Plugin, app_design_id: nil, token: 'plugin1', condition: {}) }
      let(:plugin2_1) { mock(App::Plugin, app_design_id: 1, token: 'plugin2_1', condition: {}) }
      let(:plugin2_2) { mock(App::Plugin, app_design_id: 2, token: 'plugin2_2', condition: {}) }
      let(:plugin3) { mock(App::Plugin, app_design_id: 3, token: 'plugin3', condition: {}) }
      let(:settings_template1) { mock(App::SettingsTemplate, template: template1, plugin: plugin1) }
      let(:settings_template2_1) { mock(App::SettingsTemplate, template: template2_1, plugin: plugin2_1) }
      let(:settings_template2_2) { mock(App::SettingsTemplate, template: template2_2, plugin: plugin2_2) }
      let(:settings_template3) { mock(App::SettingsTemplate, plugin: plugin3) }
      let(:addon_plan1) { mock(AddonPlan, addon: addon1, addon_id: addon1.id, kind: 'addon_kind1', settings_templates: [settings_template1]) }
      let(:addon_plan2) { mock(AddonPlan, addon: addon2, addon_id: addon2.id, kind: 'addon_kind2', settings_templates: [settings_template2_1, settings_template2_2]) }
      let(:addon_plan3) { mock(AddonPlan, addon: addon3, addon_id: addon3.id, kind: 'addon_kind3', settings_templates: [settings_template3]) }

      before do
        site.stub_chain(:addon_plans, :includes, :order) { [addon_plan1, addon_plan2, addon_plan3] }
        site.stub_chain(:kits, :includes, :order) { [kit1, kit2] }
      end

      it "includes template of this addon_plan settings_template" do
        settings.kits.should eq({
          "1" => {
            skin: { id: "skin_token1" },
            plugins: {
              "addon_kind1" => {
                plugins: {
                  "addon_kind2" => {
                    settings: {
                      close_button_position: "right"
                    },
                    allowed_settings: {
                      close_button_position: {
                        values: ["left", "right"]
                      }
                    },
                    id: "plugin2_1",
                  }
                },
                settings: {
                  autoplay: false
                },
                allowed_settings: {
                  autoplay: {
                    values: [true, false]
                  }
                },
                id: "plugin1",
              }
            }
          },
          "2" => {
            skin: { id: "skin_token2" },
            plugins: {
              "addon_kind1" => {
                plugins: {
                  "addon_kind2" => {
                    settings: {
                      close_button_position: "left"
                    },
                    allowed_settings: {
                      close_button_position: {
                        values: ["left", "right"]
                      }
                    },
                    id: "plugin2_2",
                  }
                },
                settings: {
                  autoplay: true
                },
                allowed_settings: {
                  autoplay: {
                    values: [true, false]
                  }
                },
                id: "plugin1",
              }
            }
          }
        })
      end
    end

    context "with no kits" do
      it "returns a empty hash" do
        settings.kits.should eq({})
      end
    end
  end

end
