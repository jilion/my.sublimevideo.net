require 'spec_helper'

describe DealsController do

  it { get(with_subdomain('my', 'd/rts1')).should route_to('deals#show', id: 'rts1') }

end
