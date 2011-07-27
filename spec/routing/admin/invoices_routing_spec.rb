require 'spec_helper'

describe Admin::InvoicesController do

  it { should route(:get, "admin/invoices").to(:action => :index) }
  it { should route(:get, "admin/invoices/1/edit").to(:action => :edit, :id => "1") }
  it { should route(:put, "admin/invoices/1/retry_charging").to(:action => :retry_charging, :id => "1") }

end
