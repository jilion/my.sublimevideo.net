require 'spec_helper'

describe Billing do
  
  # We specs those values since there are SOOOOOO HUGELY IMPORTANT, WE SHOULD GET ERRORS ON ANY CHANGE!!!!
  
  specify { Billing.trial_days.should == 10.days }
  specify { Billing.billing_period.should == 1.month }
  specify { Billing.minimum_amount.should == 800 }
  
end
