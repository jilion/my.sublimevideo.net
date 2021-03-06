require 'fast_spec_helper'
require 'config/sidekiq'
require 'support/matchers/sidekiq_matchers'
require 'rails/railtie' # for Carrierwave
require 'config/carrierwave' # for fog_mock

require 'services/settings_generator'

Design = Class.new unless defined?(Design)
App::Plugin = Class.new unless defined?(App::Plugin)
AddonPlanSettings = Class.new unless defined?(AddonPlanSettings)
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

  let(:site) { double("Site",
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
    default_kit: double(identifier: '1')
  )}
  let(:settings) { described_class.new(site) }

  describe ".update_all!" do
    before { Site.stub(:find) { site } }

    context "site active" do
      before { site.stub(:active?) { true } }

      it "uploads all settings types when accessible_stage is 'beta'" do
        site.stub(:accessible_stage) { 'beta' }
        site.stub(:player_mode) { 'beta' }
        described_class.update_all!(site.id)
        described_class.new(site).cdn_files.all? { |cdn_file| cdn_file.should be_present }
      end

      it "uploads all settings types when accessible_stage is 'stable'" do
        described_class.update_all!(site.id)
        described_class.new(site).cdn_files.all? { |cdn_file| cdn_file.should be_present }
      end

      it "increments metrics" do
        Librato.should_receive(:increment).with('settings.update', source: 'settings')
        described_class.update_all!(site.id)
      end

      context "when suspended" do
        before { site.stub(:active?) { false } }

        it "removes all settings types" do
          described_class.update_all!(site.id)
          described_class.new(site).cdn_files.all? { |cdn_file| cdn_file.should_not be_present }
        end

        it "increments metrics" do
          Librato.should_receive(:increment).with('settings.delete', source: 'settings')
          described_class.update_all!(site.id)
        end
      end
    end
  end

  describe 'cdn_files' do
    describe 'new settings' do
      let(:cdn_file) { described_class.new(site).cdn_files[0] }

      it 'has new path' do
        cdn_file.path.should eq "s2/abcd1234.js"
      end

      it 'new settings have non-mangled content' do
        File.open(cdn_file.file) do |f|
          f.read.should eq "/*! SublimeVideo settings  | (c) 2013 Jilion SA | http://sublimevideo.net\n*/(function(){ sublime_.define(\"settings\",[],function(){var e,t,i;return t={},e={},i={license:{\"hosts\":[\"test.com\",\"test.net\"],\"stagingHosts\":[\"test-staging.net\"],\"devHosts\":[\"test.dev\"],\"path\":\"path\",\"wildcard\":true,\"stage\":\"stable\"},app:{},kits:{},defaultKit:\"1\"},t.exports=i,t.exports||e});;sublime_.component('settings');})();"
        end
      end
    end
  end

  describe "#app_settings" do
    context "with a addon_plan with a addon_plan_settings not linked to a plugin" do
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
      let(:addon) { double(Addon) }
      let(:addon_plan_settings) { double(AddonPlanSettings, template: template, app_plugin_id: nil) }
      let(:addon_plan) { double(AddonPlan, addon: addon, settings: [addon_plan_settings], kind: 'stats') }

      before do
        site.stub_chain(:addon_plans, :includes, :order) { [addon_plan] }
      end

      it "includes template of this addon_plan addon_plan_settings" do
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
    context "with a addon_plan with a addon_plan_settings not linked to a plugin" do
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
      let(:design1) { double(Design) }
      let(:design2) { double(Design) }
      let(:kit1) { double(Kit, id: 1, identifier: '1', design_id: 1, design: design1, skin_token: 'skin_token1', skin_mod: 'foo/bar', settings: kit_settings1) }
      let(:kit2) { double(Kit, id: 2, identifier: '2', design_id: 2, design: design2, skin_token: 'skin_token2', skin_mod: 'foo/bar2', settings: kit_settings2) }
      let(:addon1) { double(Addon, id: 1, name: 'addon1', parent_addon_id: nil) }
      let(:addon2) { double(Addon, id: 2, name: 'addon2', parent_addon_id: addon1.id) }
      let(:addon3) { double(Addon, id: 3, name: 'addon3', parent_addon_id: nil) }
      let(:plugin1) { double(App::Plugin, id: 1, design_id: nil, token: 'plugin1', mod: 'foo/bar') }
      let(:plugin2_1) { double(App::Plugin, id: 2, design_id: 1, token: 'plugin2_1', mod: 'foo/bar2') }
      let(:plugin2_2) { double(App::Plugin, id: 3, design_id: 2, token: 'plugin2_2', mod: 'foo/bar3') }
      let(:plugin3) { double(App::Plugin, id: 4, design_id: 3, token: 'plugin3', mod: 'foo/bar4') }
      let(:addon_plan_settings1) { double(AddonPlanSettings, template: template1, app_plugin_id: plugin1.id, plugin: plugin1) }
      let(:addon_plan_settings2_1) { double(AddonPlanSettings, template: template2_1, app_plugin_id: plugin2_1.id, plugin: plugin2_1) }
      let(:addon_plan_settings2_2) { double(AddonPlanSettings, template: template2_2, app_plugin_id: plugin2_2.id, plugin: plugin2_2) }
      let(:addon_plan_settings3) { double(AddonPlanSettings, template: {}, app_plugin_id: plugin3.id, plugin: plugin3) }
      let(:addon_plan1) { double(AddonPlan, addon: addon1, addon_id: addon1.id, addon_name: 'addon1', kind: 'addon_kind1', settings: [addon_plan_settings1], settings_for: addon_plan_settings1) }
      let(:addon_plan2) { double(AddonPlan, addon: addon2, addon_id: addon2.id, addon_name: 'addon2', kind: 'addon_kind2', settings: [addon_plan_settings2_1, addon_plan_settings2_2]) }
      let(:addon_plan3) { double(AddonPlan, addon: addon3, addon_id: addon3.id, addon_name: 'addon3', kind: 'addon_kind3', settings: [addon_plan_settings3], settings_for: nil) }

      before do
        site.stub_chain(:addon_plans, :includes, :order) { [addon_plan1, addon_plan2, addon_plan3] }
        site.stub_chain(:kits, :includes, :order) { [kit1, kit2] }
        addon_plan2.stub(:settings_for).with(design1) { addon_plan_settings2_1 }
        addon_plan2.stub(:settings_for).with(design2) { addon_plan_settings2_2 }
      end

      it "includes template of this addon_plan addon_plan_settings without the plugin's modules" do
        settings.kits(false).should eq({
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

      it "includes template of this addon_plan addon_plan_settings with the plugin's modules" do
        settings.kits(true).should eq({
          "1" => {
            skin: { module: 'foo/bar' },
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
                    id: "plugin2_1", :module => "foo/bar2"
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
                id: "plugin1", :module => "foo/bar"
              }
            }
          },
          "2" => {
            skin: { module: 'foo/bar2' },
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
                    id: "plugin2_2", :module => "foo/bar3"
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
                id: "plugin1", :module => "foo/bar"
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
