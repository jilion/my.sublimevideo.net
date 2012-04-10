require 'spec_helper'

describe TicketsController do

  it { post(with_subdomain('my', 'help')).should         route_to('tickets#create') }

end
