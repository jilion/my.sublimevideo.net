require 'spec_helper'

describe Admin::InvoicesController do

  it { get(with_subdomain('admin', 'invoices')).should                  route_to('admin/invoices#index') }
  it { get(with_subdomain('admin', 'invoices/1/edit')).should           route_to('admin/invoices#edit', id: '1') }
  it { put(with_subdomain('admin', 'invoices/1/retry_charging')).should route_to('admin/invoices#retry_charging', id: '1') }

end
