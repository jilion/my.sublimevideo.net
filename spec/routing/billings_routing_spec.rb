require 'spec_helper'

describe BillingsController do

  it { { get: '/account/billing/edit' }.should route_to(controller: 'billings', action: 'edit') }
  it { { put: '/account/billing' }.should route_to(controller: 'billings', action: 'update') }

end
