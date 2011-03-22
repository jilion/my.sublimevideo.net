require 'spec_helper'

describe Admin::PlansController do

  it { should route(:get,  "admin/plans/new").to(:action => :new) }
  it { should route(:get,  "admin/plans").to(:action => :index) }
  it { should route(:post, "admin/plans").to(:action => :create) }

end
