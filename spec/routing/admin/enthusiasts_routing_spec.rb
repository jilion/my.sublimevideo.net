require 'spec_helper'

describe Admin::EnthusiastsController do
  
  it { should route(:get, "/admin/enthusiasts").to(:action => :index) }
  it { should route(:get, "/admin/enthusiasts/1").to(:action => :show, :id => 1) }
  
end