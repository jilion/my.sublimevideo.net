require 'fast_spec_helper'
require 'rails/railtie'

require 'services/settings_sanitizer'

describe SettingsSanitizer do
  let(:site)        { stub(touch: true) }
  let(:kit)         { stub(design: stub, site: site, site_id: 1) }
  let(:addon_plan1) { stub(addon_name: 'addonName1') }
  let(:addon_plan2) { stub(addon_name: 'addonName2') }
  let(:addon_plan3) { stub(addon_name: 'addonName3') }
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
      stringSetting2: {
        type: 'string'
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
      },
      sizeSetting: {
        type: 'size',
        default: '640'
      }
    }
  }
  let(:settings) {
    {
      addonName1: {
        booleanSetting: '1',
        floatSetting: 0.8,
        stringSetting: 'foo',
        stringSetting2: 'bar',
        imageSetting: 'http://mydomain.com/image.png',
        urlSetting: '//mydomain.com',
        buttonsSetting: ['google+', 'pinterest'],
        sizeSetting: ['640', '']
      },
      addonName2: {
        booleanSetting: '3',
        floatSetting: 2,
        stringSetting: 'baz',
        imageSetting: 'mydomain.com/image.png',
        urlSetting: 'mydomain.com',
        buttonsSetting: 'google+, foo  pinterest,   bar twitter',
        sizeSetting: ['640', '360']
      },
      addonName3: {
        urlSetting: '',
        sizeSetting: ['640 360']
      }
    }
  }
  let(:service) { described_class.new(kit, settings) }

  describe '#sanitize' do
    before do
      kit.stub_chain(:site, :addon_plan_for_addon_name).with(:addonName1) { addon_plan1 }
      kit.stub_chain(:site, :addon_plan_for_addon_name).with(:addonName2) { addon_plan2 }
      kit.stub_chain(:site, :addon_plan_for_addon_name).with(:addonName3) { addon_plan3 }
      addon_plan1.stub_chain(:settings_template_for, :try) { settings_template }
      addon_plan2.stub_chain(:settings_template_for, :try) { settings_template }
      addon_plan3.stub_chain(:settings_template_for, :try) { settings_template }
    end

    it 'returns sanitize settings' do
      service.sanitize.should == {
        'addonName1' => {
          booleanSetting: true,
          floatSetting: 0.8,
          stringSetting: 'foo',
          stringSetting2: 'bar',
          imageSetting: 'http://mydomain.com/image.png',
          urlSetting: '//mydomain.com',
          buttonsSetting: %w[google+ pinterest],
          sizeSetting: '640'
        },
        'addonName2' => {
          booleanSetting: true,
          floatSetting: 0.45,
          imageSetting: 'http://mydomain.com/image.png',
          urlSetting: 'http://mydomain.com',
          buttonsSetting: %w[google+ pinterest twitter],
          sizeSetting: '640x360'
        },
        'addonName3' => {
          sizeSetting: '640'
        }
      }
    end
  end

end
