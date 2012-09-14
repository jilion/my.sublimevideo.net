require 'spec_helper'

describe UserAgent::Comparable do

  describe "#==" do
    specify { UserAgent.new("Mozilla").should            == UserAgent.new("Mozilla") }
    specify { UserAgent.new("Mozilla", "5.0").should     == UserAgent.new("Mozilla", "5.0") }
    specify { UserAgent.new("Mozilla", "5.0").should_not == UserAgent.new("Mozilla", "4.0") }
    specify { UserAgent.new("Mozilla", "5.0").should_not == UserAgent.new("Internet Explorer", "4.0") }
  end

  describe "#<=" do
    specify { UserAgent.new("Mozilla").should            <= UserAgent.new("Mozilla") }
    specify { UserAgent.new("Mozilla", "4.0").should     <= UserAgent.new("Mozilla", "5.0") }
    specify { UserAgent.new("Mozilla", "5.0").should     <= UserAgent.new("Mozilla", "5.0") }
    specify { UserAgent.new("Mozilla").should_not        <= UserAgent.new("Opera") }
    specify { UserAgent.new("Mozilla", "5.0").should_not <= UserAgent.new("Mozilla", "4.0") }
    specify { UserAgent.new("Mozilla", "5.0").should_not <= UserAgent.new("Internet Explorer", "6.0") }
  end

  describe "#<" do
    specify { UserAgent.new("Mozilla", "4.0").should     < UserAgent.new("Mozilla", "5.0") }
    specify { UserAgent.new("Mozilla", "4.0").should     < UserAgent.new("Mozilla", "11.0") }
    specify { UserAgent.new("Mozilla").should_not        < UserAgent.new("Mozilla") }
    specify { UserAgent.new("Mozilla", "5.0").should_not < UserAgent.new("Mozilla", "4.0") }
    specify { UserAgent.new("Mozilla", "5.0").should_not < UserAgent.new("Internet Explorer", "6.0") }
  end

  describe "#>" do
    specify { UserAgent.new("Mozilla", "5.0").should     > UserAgent.new("Mozilla", "4.0") }
    specify { UserAgent.new("Mozilla").should_not        > UserAgent.new("Mozilla") }
    specify { UserAgent.new("Mozilla", "4.0").should_not > UserAgent.new("Mozilla", "5.0") }
    specify { UserAgent.new("Mozilla", "5.0").should_not > UserAgent.new("Internet Explorer", "4.0") }
  end

  describe "#>=" do
    specify { UserAgent.new("Mozilla").should            >= UserAgent.new("Mozilla") }
    specify { UserAgent.new("Mozilla", "5.0").should     >= UserAgent.new("Mozilla", "4.0") }
    specify { UserAgent.new("Mozilla", "5.0").should     >= UserAgent.new("Mozilla", "5.0") }
    specify { UserAgent.new("Mozilla", "4.0").should_not >= UserAgent.new("Mozilla", "5.0") }
    specify { UserAgent.new("Mozilla", "5.0").should_not >= UserAgent.new("Internet Explorer", "4.0") }
  end

end
