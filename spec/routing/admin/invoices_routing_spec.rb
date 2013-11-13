require 'spec_helper'

describe Admin::InvoicesController do

  it { expect(get(with_subdomain('admin', 'invoices'))).to                  route_to('admin/invoices#index') }
  it { expect(get(with_subdomain('admin', 'invoices/1/edit'))).to           route_to('admin/invoices#edit', id: '1') }

end
