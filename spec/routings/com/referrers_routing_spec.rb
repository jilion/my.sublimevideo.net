require 'spec_helper'

describe Com::ReferrersController do

  it { get('r/c/nln2ofdf').should route_to('com/referrers#redirect', type: 'c', token: 'nln2ofdf') }

end
