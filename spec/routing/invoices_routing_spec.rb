require 'spec_helper'

describe InvoicesController do

  it { should route(:get,  "sites/1/invoices").to(:action => :index, :site_id => '1') }
  it { should route(:get,  "invoices/AWQE123RTY").to(:action => :show, :id => 'AWQE123RTY') }
  it { should route(:put,  "invoices/AWQE123RTY/pay").to(:action => :pay, :id => 'AWQE123RTY') }

end
