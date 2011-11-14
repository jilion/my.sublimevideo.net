require 'spec_helper'

describe My::BillingsController do

  it { get(with_subdomain('my', 'account/billing/edit')).should route_to('my/billings#edit') }
  it { put(with_subdomain('my', 'account/billing')).should route_to('my/billings#update') }

end
