require 'spec_helper'

describe Admin::Admins::RegistrationsController do

  it { should route(:get,    "/admin/account/edit").to(:controller => "admin/admins/registrations", :action => :edit) }
  it { should route(:put,    "/admin/account").to(:controller => "admin/admins/registrations", :action => :update) }
  it { should route(:delete, "/admin/account").to(:controller => "admin/admins/registrations", :action => :destroy) }

end
