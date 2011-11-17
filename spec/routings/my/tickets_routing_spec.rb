require 'spec_helper'

describe My::TicketsController do

  it { post(with_subdomain('my', 'help')).should         route_to('my/tickets#create') }

end
