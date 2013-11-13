require 'spec_helper'

describe InvoicesController do

  it { expect(get(with_subdomain('my', 'sites/1/invoices'))).to       route_to('invoices#index', site_id: '1') }
  it { expect(get(with_subdomain('my', 'invoices/AWQE123RTY'))).to    route_to('invoices#show', id: 'AWQE123RTY') }
  it { expect(put(with_subdomain('my', 'sites/1/invoices/retry'))).to route_to('invoices#retry', site_id: '1') }
  it { expect(put(with_subdomain('my', 'invoices/retry_all'))).to     route_to('invoices#retry_all') }

end
