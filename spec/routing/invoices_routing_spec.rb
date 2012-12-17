require 'spec_helper'

describe InvoicesController do

  it { get(with_subdomain('my', 'sites/1/invoices')).should       route_to('invoices#index', site_id: '1') }
  it { get(with_subdomain('my', 'invoices/AWQE123RTY')).should    route_to('invoices#show', id: 'AWQE123RTY') }
  it { put(with_subdomain('my', 'sites/1/invoices/retry')).should route_to('invoices#retry', site_id: '1') }
  it { put(with_subdomain('my', 'invoices/retry_all')).should     route_to('invoices#retry_all') }

end
