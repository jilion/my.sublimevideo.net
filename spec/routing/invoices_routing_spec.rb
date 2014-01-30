require 'spec_helper'

describe InvoicesController do

  it { get(with_subdomain('my', 'sites/1/invoices')).should       route_to('invoices#index', site_id: '1') }
  it { get(with_subdomain('my', 'invoices/AWQE123RTY')).should    route_to('invoices#show', id: 'AWQE123RTY') }

end
