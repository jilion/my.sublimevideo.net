require 'spec_helper'

describe Billing do
  
  # We specs those values since there are SOOOOOO HUGELY IMPORTANT, WE SHOULD GET ERRORS ON ANY CHANGE!!!!
  
  specify { Billing.days_before_suspend_user.should == 10 }
  specify { Billing.max_charging_attempts.should == 5 }
  
end
