require 'fast_spec_helper'
require 'configurator'
require 'rails/railtie'
require 'fog'
require 'config/carrierwave' # for fog_mock

require 'services/player_mangler'
require 'services/settings_generator'
require 'wrappers/s3_wrapper'
require 'wrappers/cdn_file'
require 'models/app'

App::Design = Class.new unless defined?(App::Design)
App::Plugin = Class.new unless defined?(App::Plugin)
App::SettingsTemplate = Class.new unless defined?(App::SettingsTemplate)
Site = Class.new unless defined?(Site)
Kit = Class.new unless defined?(Kit)
Addon = Class.new unless defined?(Addon)
AddonPlan = Class.new unless defined?(AddonPlan)

describe SettingsGenerator, :fog_mock do
  before {
    site.stub_chain(:addon_plans, :includes, :order) { [] }
    site.stub_chain(:kits, :includes, :order) { [] }
    AddonPlan.stub(:get)
    Librato.stub(:increment)
  }

  let(:site) { mock("Site",
    id: 1,
    token: 'abcd1234',
    hostname: 'test.com',
    extra_hostnames: 'test.net', extra_hostnames?: true,
    dev_hostnames: 'test.dev', dev_hostnames?: true,
    staging_hostnames: 'test-staging.net', staging_hostnames?: true,
    wildcard: true, wildcard?: true,
    path: 'path', path?: true,
    subscribed_to?: true,
    accessible_stage: 'stable',
    default_kit: stub(identifier: '1')
  )}
  let(:settings) { described_class.new(site) }

  describe ".update_all!" do
    before { Site.stub(:find) { site } }

    context "site active" do
      before { site.stub(:state) { 'active' } }

      it "uploads all settings types when accessible_stage is 'beta'" do
        site.stub(:accessible_stage) { 'beta' }
        site.stub(:player_mode) { 'beta' }
        described_class.update_all!(site.id)
        described_class.new(site).cdn_file.should be_present
      end

      it "uploads all settings types when accessible_stage is 'stable'" do
        described_class.update_all!(site.id)
        described_class.new(site).should be_present
      end

      it "increments metrics" do
        Librato.should_receive(:increment).with('settings.update', source: 'settings')
        described_class.update_all!(site.id)
      end

      context "when suspended" do
        before { site.stub(:state) { 'suspended' } }

        it "removes all settings types" do
          described_class.update_all!(site.id)
          described_class.new(site).should_not be_present
        end

        it "increments metrics" do
          Librato.should_receive(:increment).with('settings.delete', source: 'settings')
          described_class.update_all!(site.id)
        end
      end
    end
  end

  describe "file" do
    let(:file) { described_class.new(site).file }

    it "has good content" do
      File.open(file) do |f|
        f.read.should eq "sublime_.iu(\"ko\",[],function(){var a;return a={kr:{\"ku\":[\"test.com\",\"test.net\"],\"kw\":[\"test-staging.net\"],\"kv\":[\"test.dev\"],\"kz\":\"path\",\"ia\":true,\"ib\":\"stable\"},sa:{},ks:{},kt:\"1\"},[a]})\n"
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
      let(:settings_template) { mock(App::SettingsTemplate, template: template, app_plugin_id: nil) }
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
      let(:design1) { mock(App::Design) }
      let(:design2) { mock(App::Design) }
      let(:kit1) { mock(Kit, id: 1, identifier: '1', app_design_id: 1, design: design1, skin_token: 'skin_token1', settings: kit_settings1) }
      let(:kit2) { mock(Kit, id: 2, identifier: '2', app_design_id: 2, design: design2, skin_token: 'skin_token2', settings: kit_settings2) }
      let(:addon1) { mock(Addon, id: 1, name: 'addon1', parent_addon_id: nil) }
      let(:addon2) { mock(Addon, id: 2, name: 'addon2', parent_addon_id: addon1.id) }
      let(:addon3) { mock(Addon, id: 3, name: 'addon3', parent_addon_id: nil) }
      let(:plugin1) { mock(App::Plugin, id: 1, app_design_id: nil, token: 'plugin1', condition: {}) }
      let(:plugin2_1) { mock(App::Plugin, id: 2, app_design_id: 1, token: 'plugin2_1', condition: {}) }
      let(:plugin2_2) { mock(App::Plugin, id: 3, app_design_id: 2, token: 'plugin2_2', condition: {}) }
      let(:plugin3) { mock(App::Plugin, id: 4, app_design_id: 3, token: 'plugin3', condition: {}) }
      let(:settings_template1) { mock(App::SettingsTemplate, template: template1, app_plugin_id: plugin1.id, plugin: plugin1) }
      let(:settings_template2_1) { mock(App::SettingsTemplate, template: template2_1, app_plugin_id: plugin2_1.id, plugin: plugin2_1) }
      let(:settings_template2_2) { mock(App::SettingsTemplate, template: template2_2, app_plugin_id: plugin2_2.id, plugin: plugin2_2) }
      let(:settings_template3) { mock(App::SettingsTemplate, template: {}, app_plugin_id: plugin3.id, plugin: plugin3) }
      let(:addon_plan1) { mock(AddonPlan, addon: addon1, addon_id: addon1.id, kind: 'addon_kind1', settings_templates: [settings_template1], settings_template_for: settings_template1) }
      let(:addon_plan2) { mock(AddonPlan, addon: addon2, addon_id: addon2.id, kind: 'addon_kind2', settings_templates: [settings_template2_1, settings_template2_2]) }
      let(:addon_plan3) { mock(AddonPlan, addon: addon3, addon_id: addon3.id, kind: 'addon_kind3', settings_templates: [settings_template3], settings_template_for: nil) }

      before do
        site.stub_chain(:addon_plans, :includes, :order) { [addon_plan1, addon_plan2, addon_plan3] }
        site.stub_chain(:kits, :includes, :order) { [kit1, kit2] }
        addon_plan2.stub(:settings_template_for).with(design1) { settings_template2_1 }
        addon_plan2.stub(:settings_template_for).with(design2) { settings_template2_2 }
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
