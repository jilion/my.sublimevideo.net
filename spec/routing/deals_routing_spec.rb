require 'spec_helper'

describe DealsController do

  it { expect(get(with_subdomain('my', 'd/rts1'))).to route_to('deals#show', id: 'rts1') }

end
