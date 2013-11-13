require 'spec_helper'

describe LayoutHelper do

  describe '#sticky_notices' do
    let(:user)                   { double }
    let(:sites)                  { double }
    let(:site_will_leave_trial)  { double }
    let(:sites_will_leave_trial) { [{ site: site_will_leave_trial }] }
    before do
      expect(helper).to receive(:credit_card_warning).with(user).and_return(true)
      expect(helper).to receive(:billing_address_incomplete).with(user).and_return(true)
    end

    it {
      expect(helper.sticky_notices(user, sites)).to eq({
        credit_card_warning: true,
        billing_address_incomplete: true
      })
    }
  end

end
