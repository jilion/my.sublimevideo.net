require 'spec_helper'

describe BillingsController do

  it { get(with_subdomain('my', 'account/billing/edit')).should route_to('billings#edit') }
  it { put(with_subdomain('my', 'account/billing')).should route_to('billings#update') }

end
