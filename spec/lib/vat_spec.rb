require 'fast_spec_helper'
require 'active_support/core_ext'
require File.expand_path('lib/vat')

describe Vat do

  describe "self.for_country" do
    specify { Vat.for_country('CH').should == 0.08 }
    specify { Vat.for_country('FR').should == 0.00 }
    specify { Vat.for_country('CN').should == 0.00 }
    specify { Vat.for_country('US').should == 0.00 }
  end

  describe "self.for_country?" do
    specify { Vat.for_country?('CH').should be_true }
    specify { Vat.for_country?('FR').should be_false }
    specify { Vat.for_country?('CN').should be_false }
    specify { Vat.for_country?('US').should be_false }
  end

end
