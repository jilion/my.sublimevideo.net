# coding: utf-8
require 'spec_helper'

describe EnthusiastSite do

  context "with valid attributes" do
    subject { create(:enthusiast_site) }

    its(:hostname)   { should eq "youtube.com" }
    its(:enthusiast) { should be_present }

    it { should be_valid }
  end

  describe "Validations" do
    subject { create(:enthusiast_site) }

    [:hostname].each do |attribute|
      it { should allow_mass_assignment_of(attribute) }
    end

    it { should validate_presence_of(:hostname) }

    specify { EnthusiastSite.validators_on(:hostname).map(&:class).should == [ActiveModel::Validations::PresenceValidator, HostnameValidator] }
  end

end

# == Schema Information
#
# Table name: enthusiast_sites
#
#  created_at    :datetime
#  enthusiast_id :integer
#  hostname      :string(255)
#  id            :integer          not null, primary key
#  updated_at    :datetime
#
# Indexes
#
#  index_enthusiast_sites_on_enthusiast_id  (enthusiast_id)
#

