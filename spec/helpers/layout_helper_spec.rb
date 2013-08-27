require 'spec_helper'

describe LayoutHelper do

  describe '#sticky_notices' do
    let(:user)                   { double }
    let(:sites)                  { double }
    let(:site_will_leave_trial)  { double }
    let(:sites_will_leave_trial) { [{ site: site_will_leave_trial }] }
    before do
      helper.should_receive(:credit_card_warning).with(user).and_return(true)
      helper.should_receive(:billing_address_incomplete).with(user).and_return(true)
    end

    it {
      helper.sticky_notices(user, sites).should == {
        credit_card_warning: true,
        billing_address_incomplete: true
      }
    }
  end

end
