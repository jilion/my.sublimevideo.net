require 'spec_helper'

describe SitesController do
  
  it { should route(:get,    "sites").to(:action => :index) }
  it { should route(:get,    "sites/new").to(:action => :new) }
  it { should route(:get,    "sites/1/code").to(:action => :code, :id => "1") }
  it { should route(:get,    "sites/1/transition").to(:action => :transition, :id => "1") }
  it { should route(:get,    "sites/1/edit").to(:action => :edit, :id => "1") }
  it { should route(:post,   "sites").to(:action => :create) }
  it { should route(:put,    "sites/1").to(:action => :update, :id => "1") }
  it { should route(:put,    "sites/1/activate").to(:action => :activate, :id => "1") }
  it { should route(:delete, "sites/1").to(:action => :destroy, :id => "1") }
  it { should route(:get,    "sites/1/state").to(:action => :state, :id => "1") }
  it { should route(:get,    "sites/1/usage").to(:action => :usage, :id => "1") }
  
end