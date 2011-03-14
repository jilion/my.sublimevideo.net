require 'spec_helper'

describe TransactionsController do

  it { should route(:post, "transaction/payment_ok").to(:action => :payment_ok) }
  it { should route(:post, "transaction/payment_ko").to(:action => :payment_ko) }

end
