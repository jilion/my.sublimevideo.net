require 'spec_helper'

describe Admin::DashboardsController do

  it { should route(:get, "admin/dashboard").to(:action => :show) }

end