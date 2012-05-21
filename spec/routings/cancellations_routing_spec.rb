require 'spec_helper'

describe Users::CancellationsController do

  it { get(with_subdomain('my', 'account/cancel')).should  route_to('users/cancellations#new') }
  it { post(with_subdomain('my', 'account/cancel')).should route_to('users/cancellations#create') }

end
