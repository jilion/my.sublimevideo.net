require 'spec_helper'

describe My::TicketsController do

  it { get(with_subdomain('my', 'support')).should          route_to('my/tickets#new') }
  it { post(with_subdomain('my', 'support')).should         route_to('my/tickets#create') }

  it { put(with_subdomain('my', 'support/1')).should_not    be_routable }
  it { delete(with_subdomain('my', 'support/1')).should_not be_routable }

end
