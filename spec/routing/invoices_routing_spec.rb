require 'spec_helper'

describe InvoicesController do
  
  it { should route(:get, "invoices").to(:action => :index) }
  it { should route(:get, "invoices/1").to(:action => :show, :id => "1") }
  
end