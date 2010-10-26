require 'spec_helper'

describe Admin::ReferrersController do
  
  it { should route(:get, "admin/referrers").to(:action => :index) }
  
end