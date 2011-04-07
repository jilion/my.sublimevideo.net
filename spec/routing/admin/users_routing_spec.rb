require 'spec_helper'

describe Admin::UsersController do

  it { should route(:get, "admin/users").to(:action => :index) }
  it { should route(:get, "admin/users/1").to(:action => :show, :id => "1") }
  it { should route(:get, "admin/users/1/become").to(:action => :become, :id => "1") }

end
