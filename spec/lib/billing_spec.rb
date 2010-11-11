require 'spec_helper'

describe Billing do
  
  # We specs those values since there are SOOOOOO HUGELY IMPORTANT, WE SHOULD GET ERRORS ON ANY CHANGE!!!!
  
  specify { Billing.trial_days.should == 10 }
  specify { Billing.minimum_amount.should == 800 }
  
end
