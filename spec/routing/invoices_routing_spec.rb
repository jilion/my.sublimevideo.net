require 'spec_helper'

describe InvoicesController do
  
  it { should route(:get, "invoices/usage").to(:action => :usage) }
  it { should route(:get, "invoices/AWQE123RTY").to(:action => :show, :id => 'AWQE123RTY') }
  
end