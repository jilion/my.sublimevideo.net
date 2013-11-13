require 'spec_helper'

describe BillingsController do

  it { expect(get(with_subdomain('my', 'account/billing/edit'))).to route_to('billings#edit') }
  it { expect(put(with_subdomain('my', 'account/billing'))).to route_to('billings#update') }

end
