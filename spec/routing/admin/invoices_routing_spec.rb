require 'spec_helper'

describe Admin::InvoicesController do

  it { { get: 'admin/invoices' }.should                  route_to(controller: 'admin/invoices', action: 'index') }
  it { { get: 'admin/invoices/1/edit' }.should           route_to(controller: 'admin/invoices', action: 'edit', id: '1') }
  it { { put: 'admin/invoices/1/retry_charging' }.should route_to(controller: 'admin/invoices', action: 'retry_charging', id: '1') }

end
