require 'spec_helper'

describe Billing do
  
  # We specs those values since there are SOOOOOO HUGELY IMPORTANT, WE SHOULD GET ERRORS ON ANY CHANGE!!!!
  
  specify { Billing.days_before_creating_invoice.should == 1 }
  specify { Billing.days_before_charging.should == 3 }
  specify { Billing.hours_between_retries_before_user_suspend.should == 6 }
  specify { Billing.days_before_suspend_user.should == 10 }
  specify { Billing.max_charging_attempts.should == 5 }
  specify { Billing.minimum_billable_amount.should == 300 }
  specify { Billing.beta_discount_rate.should == 0.2 }
  specify { Billing.discounted_months.should == 3 }
  
end