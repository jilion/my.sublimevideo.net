require 'spec_helper'

describe InvoicesController do

  it { { get: 'sites/1/invoices' }.should       route_to(controller: 'invoices', action: 'index', site_id: '1') }
  it { { get: 'invoices/AWQE123RTY' }.should    route_to(controller: 'invoices', action: 'show', id: 'AWQE123RTY') }
  it { { put: 'sites/1/invoices/retry' }.should route_to(controller: 'invoices', action: 'retry', site_id: '1') }
  it { { put: 'invoices/retry_all' }.should     route_to(controller: 'invoices', action: 'retry_all') }

end
