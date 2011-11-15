require 'spec_helper'

describe My::RefundsController do

  it { get(with_subdomain('my', 'refund')).should route_to('my/refunds#index') }
  it { post(with_subdomain('my', 'refund')).should route_to('my/refunds#create') }

end
