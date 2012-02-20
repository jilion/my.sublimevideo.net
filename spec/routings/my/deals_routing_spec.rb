require 'spec_helper'

describe My::DealsController do

  it { get(with_subdomain('my', 'd/rts1')).should route_to('my/deals#show', id: 'rts1') }

end
