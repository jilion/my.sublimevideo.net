require 'spec_helper'

describe My::InvoicesController do

  it { get(with_subdomain('my', 'sites/1/invoices')).should       route_to('my/invoices#index', site_id: '1') }
  it { get(with_subdomain('my', 'invoices/AWQE123RTY')).should    route_to('my/invoices#show', id: 'AWQE123RTY') }
  it { put(with_subdomain('my', 'sites/1/invoices/retry')).should route_to('my/invoices#retry', site_id: '1') }
  it { put(with_subdomain('my', 'invoices/retry_all')).should     route_to('my/invoices#retry_all') }

end
