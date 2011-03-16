require 'spec_helper'

describe PlansController do

  it { should route(:get,    "sites/1/plan/edit").to(:action => :edit, :site_id => "1") }
  it { should route(:put,    "sites/1/plan").to(:action => :update, :site_id => "1") }
  it { should route(:delete, "sites/1/plan").to(:action => :destroy, :site_id => "1") }

end
