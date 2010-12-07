require 'spec_helper'

describe Admin::PlansController do
  
  it { should route(:get, "admin/plans").to(:action => :index) }
  
end