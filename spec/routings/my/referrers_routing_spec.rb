require 'spec_helper'

describe My::ReferrersController do

  it { get(with_subdomain('my', 'r/c/nln2ofdf')).should route_to('my/referrers#redirect', type: 'c', token: 'nln2ofdf') }

end
