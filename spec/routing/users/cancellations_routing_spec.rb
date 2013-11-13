require 'spec_helper'

describe Users::CancellationsController do

  it { expect(get(with_subdomain('my', 'account/cancel'))).to  route_to('users/cancellations#new') }
  it { expect(post(with_subdomain('my', 'account/cancel'))).to route_to('users/cancellations#create') }

end
