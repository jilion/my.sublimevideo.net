require 'spec_helper'

describe TicketsController do

  it { { get: '/support' }.should  route_to(controller: 'tickets', action: 'new') }
  it { { post: '/support' }.should route_to(controller: 'tickets', action: 'create') }
  it { { put: '/support/1' }.should_not    be_routable }
  it { { delete: '/support/1' }.should_not be_routable }

end
