require 'fast_spec_helper'
require 'rails/railtie'

require File.expand_path('lib/service/settings_sanitizer')

describe Service::SettingsSanitizer do
  let(:site)        { stub(touch: true) }
  let(:kit)         { stub(design: stub, site: site, site_id: 1) }
  let(:addon_plan1) { stub(addon: stub(name: 'addonName1')) }
  let(:addon_plan2) { stub(addon: stub(name: 'addonName2')) }
  let(:settings_template) {
    {
      booleanSetting: {
        type: 'boolean',
        values: [true, false],
        default: true
      },
      floatSetting: {
        type: 'float',
        range: [0.1, 1],
        step: 0.1,
        default: 0.7
      },
      stringSetting: {
        type: 'string',
        values: ['foo', 'bar'],
        default: 'foo'
      },
      imageSetting: {
        type: 'image',
        default: ''
      },
      urlSetting: {
        type: 'url'
      },
      buttonsSetting: {
        type: 'array',
        item: {
          type: 'string',
          values: %w[twitter facebook pinterest google+]
        },
        default: %w[twitter facebook pinterest google+]
      }
    }
  }
  let(:settings) {
    {
      addonName1: {
        booleanSetting: '1',
        floatSetting: 0.8,
        stringSetting: 'foo',
        imageSetting: 'http://mydomain.com/image.png',
        urlSetting: '//mydomain.com',
        buttonsSetting: ['google+', 'pinterest']
      },
      addonName2: {
        booleanSetting: '3',
        floatSetting: 2,
        stringSetting: 'baz',
        imageSetting: 'mydomain.com/image.png',
        urlSetting: 'mydomain.com',
        buttonsSetting: 'google+ foo  pinterest   bar twitter'
      }
    }
  }
  let(:service) { described_class.new(kit, settings) }

  describe '#sanitize' do
    before do
      kit.stub_chain(:site, :addon_plan_for_addon_name).with(:addonName1) { addon_plan1 }
      kit.stub_chain(:site, :addon_plan_for_addon_name).with(:addonName2) { addon_plan2 }
      addon_plan1.stub_chain(:settings_template_for, :try) { settings_template }
      addon_plan2.stub_chain(:settings_template_for, :try) { settings_template }
    end

    it 'returns sanitize settings' do
      service.sanitize.should == {
        'addonName1' => {
          booleanSetting: true,
          floatSetting: 0.8,
          stringSetting: 'foo',
          imageSetting: 'http://mydomain.com/image.png',
          urlSetting: '//mydomain.com',
          buttonsSetting: 'google+ pinterest'
        },
        'addonName2' => {
          booleanSetting: true,
          floatSetting: 0.45,
          imageSetting: 'http://mydomain.com/image.png',
          urlSetting: 'http://mydomain.com',
          buttonsSetting: 'google+ pinterest twitter'
        }
      }
    end
  end

end
