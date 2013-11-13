require 'spec_helper'

describe SupportRequestsController do

  it { expect(post(with_subdomain('my', 'help'))).to route_to('support_requests#create') }

end
