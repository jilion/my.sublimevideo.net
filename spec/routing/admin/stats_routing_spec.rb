require 'spec_helper'

describe Admin::StatsController do
  
  it { should route(:get, "admin/stats").to(:action => :index) }
  it { should route(:get, "admin/stats/foo").to(:action => :show, :id => 'foo') }
  
end