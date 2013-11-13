# coding: utf-8
require 'spec_helper'

describe EnthusiastSite do

  context "with valid attributes" do
    subject { create(:enthusiast_site) }

    describe '#hostname' do
      subject { super().hostname }
      it   { should eq "youtube.com" }
    end

    describe '#enthusiast' do
      subject { super().enthusiast }
      it { should be_present }
    end

    it { should be_valid }
  end

  describe "Validations" do
    subject { create(:enthusiast_site) }

    it { should validate_presence_of(:hostname) }

    specify { expect(EnthusiastSite.validators_on(:hostname).map(&:class)).to eq([ActiveRecord::Validations::PresenceValidator, HostnameValidator]) }
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

