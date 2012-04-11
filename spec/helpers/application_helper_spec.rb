# coding: utf-8
require 'spec_helper'

describe ApplicationHelper do
  include Devise::TestHelpers

  describe "#display_bool" do
    it { helper.display_bool(true).should eq "✓" }
    it { helper.display_bool(1).should eq "✓" }
    it { helper.display_bool(0).should eq "-" }

    it { helper.display_bool(false).should eq "-" }
    it { helper.display_bool(nil).should eq "-" }
    it { helper.display_bool("").should eq "-" }
  end

  describe "#display_time" do
    let(:date) { Time.now.utc }
    it { helper.display_time(date).should eq I18n.l(date, format: :minutes_y) }
    it { helper.display_time(nil).should eq "-" }
  end

  describe "#display_percentage" do
    it { helper.display_percentage(0.1).should eq number_to_percentage(10, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.12).should eq number_to_percentage(12, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.123).should eq number_to_percentage(12.3, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.1234).should eq number_to_percentage(12.34, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.12344).should eq number_to_percentage(12.34, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.123459).should eq number_to_percentage(12.35, :precision => 2, :strip_insignificant_zeros => true) }

    it { helper.display_percentage(0.01).should eq number_to_percentage(1, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.012).should eq number_to_percentage(1.2, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.0123).should eq number_to_percentage(1.23, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.01234).should eq number_to_percentage(1.23, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.01239).should eq number_to_percentage(1.24, :precision => 2, :strip_insignificant_zeros => true) }
  end

  describe "#display_amount" do
    it { helper.display_amount(1990).should eq "$19.90" }
    it { helper.display_amount(1990, :decimals => 1).should eq "$19.9" }
    it { helper.display_amount(1900).should eq "$19" }
    it { helper.display_amount(1900, :decimals => 1).should eq "$19.0" }

    context "with tva" do
      before { sign_in create(:user, billing_country: "CH") }

      it { helper.display_amount(10000, vat: true).should eq "$108" }
    end
  end

  describe "#display_amount_with_sup" do
    it { helper.display_amount_with_sup(1990).should eq "$19<sup>.90</sup>" }
    it { helper.display_amount_with_sup(1990.0).should eq "$19<sup>.90</sup>" }
    it { helper.display_amount_with_sup(7920).should eq "$79<sup>.20</sup>" }
    it { helper.display_amount_with_sup(1900).should eq "$19" }
  end

  # describe "#info_box" do
  #   it { helper.info_box { "<p>foo</p>" }.should eq '<div class="info_box"><p>foo</p><span class="arrow"></span></div>' }
  # end

end
