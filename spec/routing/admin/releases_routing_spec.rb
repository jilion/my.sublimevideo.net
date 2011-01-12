require 'spec_helper'

describe Admin::ReleasesController do

  it { should route(:get,  "admin/releases").to(:action => :index) }
  it { should route(:post, "admin/releases").to(:action => :create) }
  it { should route(:put,  "admin/releases/1").to(:action => :update, :id => "1") }

end
