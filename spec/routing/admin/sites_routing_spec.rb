require 'spec_helper'

describe Admin::SitesController do
  
  it { should route(:get,    "admin/sites").to(:action => :index) }
  it { should route(:get,    "admin/sites/1").to(:action => :show, :id => "1") }
  
end