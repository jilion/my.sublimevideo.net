require 'spec_helper'

describe Admin::SitesController do

  it { should route(:get, "admin/sites").to(:action => :index) }
  it { should route(:get, "admin/sites/1/edit").to(:action => :edit, :id => "1") }
  it { should route(:put, "admin/sites/1").to(:action => :update, :id => "1") }

end
