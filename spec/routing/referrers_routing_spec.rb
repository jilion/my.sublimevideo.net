require 'spec_helper'

describe ReferrersController do

  it { { get: '/r/c/nln2ofdf' }.should route_to(controller: 'referrers', action: 'redirect', :type => 'c', :token => 'nln2ofdf') }

end