require 'spec_helper'

describe Www::ReferrersController do

  it { get(with_subdomain('www', 'r/c/nln2ofdf')).should route_to('www/referrers#redirect', type: 'c', token: 'nln2ofdf') }
  it { get(with_subdomain('www', 'r/b/nln2ofdf')).should route_to('www/referrers#redirect', type: 'b', token: 'nln2ofdf') }

end
