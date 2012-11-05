require 'fast_spec_helper'
require 'rails/railtie'

require 'sidekiq'
require File.expand_path('spec/config/sidekiq')
require File.expand_path('spec/support/sidekiq_custom_matchers')

require File.expand_path('lib/service/kit')
require File.expand_path('lib/service/site')

Kit = Struct.new(:params) unless defined?(Kit)

describe Service::Kit do
  let(:site)       { stub(touch: true) }
  let(:kit)        { stub(design: stub, site: site, site_id: 1) }
  let(:addon_plan) { stub }
  let(:service)    { described_class.new(kit) }

  describe "#update" do
    let(:params) { { app_design_id: 'design_id', addons: { "logo" => { "settings" => "value" } } } }
    before do
      ::Kit.stub(:transaction).and_yield
      service.stub(:set_addons_settings)
      kit.stub(:app_design_id=)
      kit.stub(:update_attributes!)
    end

    it 'sets addons_settings without app_design_id params' do
      service.should_receive(:set_addons_settings).with(params[:addons])
      service.update(params)
    end

    it 'saves kit' do
      kit.should_receive(:update_attributes!)
      service.update(params)
    end

    it 'touches site settings_updated_at' do
      site.should_receive(:touch).with(:settings_updated_at)
      service.update(params)
    end

    it 'delays the update of all settings types' do
      Service::Settings.should delay(:update_all_types!).with(kit.site_id)
      service.update(params)
    end
  end


  describe '#sanitize_new_addons_settings' do
    before do
      kit.stub_chain(:site, :addon_plan_for_addon_name) { addon_plan }
      addon_plan.stub(:settings_template_for, :template) { stub(template: {
          fooBar1: {
            type: 'boolean',
            values: [true],
            default: true
          },
          fooBar2: {
            type: 'float',
            range: [0.05, 1],
            step: 0.05,
            default: 0.7
          },
          fooBar3: {
            type: 'string',
            values: ['foo', 'bar'],
            default: 'foo'
          }
        })
      }
    end

    it 'cast booleans to real booleans' do
      service.sanitize_new_addons_settings({ 'addon' => { fooBar1: '1' } }).should == { 'addon' => { fooBar1: true } }
    end
    it { expect { service.sanitize_new_addons_settings({ 'addon' => { fooBar1: '0' } }) }.to raise_error Service::Kit::AttributeAssignmentError }

    it 'round floats to 2 decimals' do
      service.sanitize_new_addons_settings({ 'addon' => { fooBar2: '0.330001' } }).should == { 'addon' => { fooBar2: 0.33 } }
    end
    it { expect { service.sanitize_new_addons_settings({ 'addon' => { fooBar2: 0 } }) }.to raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.sanitize_new_addons_settings({ 'addon' => { fooBar2: 1.1 } }) }.to raise_error Service::Kit::AttributeAssignmentError }

    it { expect { service.sanitize_new_addons_settings({ 'addon' => { fooBar3: 'foo' } }) }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.sanitize_new_addons_settings({ 'addon' => { fooBar3: 'bar' } }) }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.sanitize_new_addons_settings({ 'addon' => { fooBar3: 'baz' } }) }.to raise_error Service::Kit::AttributeAssignmentError }
  end

  describe '#check_boolean' do
    it { expect { service.send :check_boolean,  0  }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_boolean,  1  }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_boolean, '0' }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_boolean, '1' }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_boolean,  2  }.to raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_boolean, '2' }.to raise_error Service::Kit::AttributeAssignmentError }
  end

  describe '#check_inclusion' do
    it { expect { service.send :check_number_inclusion,   0,   [0,1] }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_number_inclusion,   1,   [0,1] }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_number_inclusion,   0,   (0..1) }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_number_inclusion,   0.0007, (0..1) }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_number_inclusion,   1, (0..1) }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_number_inclusion,   '0', (0..1) }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_number_inclusion,   '1', (0..1) }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_number_inclusion,   1,   (0..1) }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_number_inclusion,  '0',  (0..1) }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_number_inclusion,  '1',  (0..1) }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_number_inclusion, 'foo', ['foo', 'bar'] }.to raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_number_inclusion,   2,   (0..1) }.to raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_number_inclusion,  '2',  (0..1) }.to raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_number_inclusion, 'foo', ['bar', 'baz'] }.to raise_error Service::Kit::AttributeAssignmentError }
  end

  describe '#check_string_inclusion' do
    it { expect { service.send :check_string_inclusion,   0,   [0,1] }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_string_inclusion,   1,   [0,1] }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_string_inclusion,  '0',  [0,1] }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_string_inclusion,  '1',  [0,1] }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_string_inclusion, 'foo', ['foo', 'bar'] }.to_not raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_string_inclusion,   2,   [0,1] }.to raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_string_inclusion,  '2',  [0,1] }.to raise_error Service::Kit::AttributeAssignmentError }
    it { expect { service.send :check_string_inclusion, 'foo', ['bar', 'baz'] }.to raise_error Service::Kit::AttributeAssignmentError }
  end

end
