require 'spec_helper'

describe PrivateApi::ReferrersController do

  it { get(with_subdomain('my', 'private_api/referrers')).should route_to('private_api/referrers#index') }

end
