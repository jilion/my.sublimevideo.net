require 'spec_helper'

describe Admin::AdminsController do

  it { should route(:get,    "/admin/admins").to(:controller => "admin/admins", :action => :index) }
  it { should route(:delete, "/admin/admins/1").to(:controller => "admin/admins", :action => :destroy, :id => '1') }

end
