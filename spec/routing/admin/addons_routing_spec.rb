require 'spec_helper'

describe Admin::AddonsController do
  
  it { should route(:get, "admin/addons").to(:action => :index) }
  
end