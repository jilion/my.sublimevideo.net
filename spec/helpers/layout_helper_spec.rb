require 'spec_helper'

describe LayoutHelper, :plans do

  describe '#sticky_notices' do
    let(:user)                   { stub }
    let(:sites)                  { stub }
    let(:site_will_leave_trial)  { stub }
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

  describe "#style_for_usage_bar_from_usage_percentage" do
    it { helper.style_for_usage_bar_from_usage_percentage(0).should eq "display:none;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.0).should eq "display:none;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.02).should eq "width:4%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.04).should eq "width:4%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.05).should eq "width:5%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.12344).should eq "width:12.34%;" }
    it { helper.style_for_usage_bar_from_usage_percentage(0.783459).should eq "width:78.35%;" }
  end

  describe "#hostname_or_token" do
    context "site with a hostname" do
      let(:site) { build(:fake_site, hostname: 'rymai.me') }

      specify { helper.hostname_or_token(site).should eq 'rymai.me' }
    end

    context "site without a hostname" do
      let(:site) { build(:fake_site, plan_id: @free_plan.id, hostname: '') }

      specify { helper.hostname_or_token(site).should eq "##{site.token}" }
    end
  end

end
