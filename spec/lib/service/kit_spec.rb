require 'fast_spec_helper'
require File.expand_path('lib/service/kit')

describe Service::Kit do
  let(:kit)        { stub(design: stub) }
  let(:addon_plan) { stub }
  let(:service)    { described_class.new(kit) }

  describe '.sanitize_new_addons_settings' do
    before do
      kit.stub_chain(:site, :addon_plan_for_addon_id) { addon_plan }
      addon_plan.stub(:settings_template_for, :template) { stub(template: {
          editable: true,
          'fooBar' => "{
            type: 'float',
            range: [0, 1],
            step: 0.05,
            default: 0.1
          }"
        })
      }
    end

    it 'round floats to 2 decimals' do
      service.sanitize_new_addons_settings({ '1' => { 'fooBar' => '0.330001' } }).should == { '1' => { 'fooBar' => 0.33 } }
    end

    it 'round floats to 2 decimals' do
      service.sanitize_new_addons_settings({ '1' => { 'fooBar' => '0.330001' } }).should == { '1' => { 'fooBar' => 0.33 } }
    end
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
