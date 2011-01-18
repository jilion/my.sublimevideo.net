require 'spec_helper'

describe ReferrersController do

  it { should route(:get, "/r/c/nln2ofdf").to(:controller => "referrers", :action => :redirect, :type => 'c', :token => 'nln2ofdf') }

end