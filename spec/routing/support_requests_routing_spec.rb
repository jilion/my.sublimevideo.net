require 'spec_helper'

describe SupportRequestsController do

  it { post(with_subdomain('my', 'help')).should route_to('support_requests#create') }

end
