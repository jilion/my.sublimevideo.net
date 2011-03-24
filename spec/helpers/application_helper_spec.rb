# coding: utf-8
require 'spec_helper'

describe ApplicationHelper do

  describe "#display_bool" do
    it { helper.display_bool(true).should == "✓" }
    it { helper.display_bool(1).should == "✓" }
    it { helper.display_bool(0).should == "-" }

    it { helper.display_bool(false).should == "-" }
    it { helper.display_bool(nil).should == "-" }
    it { helper.display_bool("").should == "-" }
  end

  describe "#display_date" do
    let(:date) { Time.now.utc }
    it { helper.display_date(date).should == I18n.l(date, :format => :minutes_timezone) }
    it { helper.display_date(nil).should == "-" }
  end

  describe "#display_percentage" do
    it { helper.display_percentage(0.1).should == number_to_percentage(10, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.12).should == number_to_percentage(12, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.123).should == number_to_percentage(12.3, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.1234).should == number_to_percentage(12.34, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.12344).should == number_to_percentage(12.34, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.123459).should == number_to_percentage(12.35, :precision => 2, :strip_insignificant_zeros => true) }

    it { helper.display_percentage(0.01).should == number_to_percentage(1, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.012).should == number_to_percentage(1.2, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.0123).should == number_to_percentage(1.23, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.01234).should == number_to_percentage(1.23, :precision => 2, :strip_insignificant_zeros => true) }
    it { helper.display_percentage(0.01239).should == number_to_percentage(1.24, :precision => 2, :strip_insignificant_zeros => true) }
  end

  describe "#display_amount" do
    it { helper.display_amount(1990).should == "$19.90" }
    it { helper.display_amount(1990, :decimals => 1).should == "$19.9" }
    it { helper.display_amount(1900).should == "$19" }
    it { helper.display_amount(1900, :decimals => 1).should == "$19.0" }
  end

  describe "#display_amount_with_sup" do
    it { helper.display_amount_with_sup(1990).should == "$19<sup>.90</sup>" }
    it { helper.display_amount_with_sup(1900).should == "$19" }
  end

  # describe "#info_box" do
  #   it { helper.info_box { "<p>foo</p>" }.should == '<div class="info_box"><p>foo</p><span class="arrow"></span></div>' }
  # end

end
