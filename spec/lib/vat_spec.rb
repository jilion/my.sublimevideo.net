require 'spec_helper'

describe Vat do
  
  describe "self.for_country" do
    specify { Vat.for_country('CH').should == 0.08 }
    specify { Vat.for_country('FR').should == 0.00 }
    specify { Vat.for_country('CN').should == 0.00 }
    specify { Vat.for_country('US').should == 0.00 }
  end
  
end
