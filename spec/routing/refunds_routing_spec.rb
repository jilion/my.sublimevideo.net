require 'spec_helper'

describe RefundsController do

  it { should route(:get,  "refund").to(:action => :index) }
  it { should route(:post, "refund").to(:action => :create) }

end
