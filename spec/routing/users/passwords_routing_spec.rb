require 'spec_helper'

describe Users::PasswordsController do

  it { should route(:get,  "/password/new").to(:controller => "devise/passwords", :action => :new) }
  it { should route(:post, "/password").to(:controller => "devise/passwords", :action => :create) }
  it { should route(:get,  "/password/edit").to(:controller => "devise/passwords", :action => :edit) }
  it { should route(:put,  "/password").to(:controller => "devise/passwords", :action => :update) }
  it { should route(:post, "/password/validate").to(:action => :validate) }

end
