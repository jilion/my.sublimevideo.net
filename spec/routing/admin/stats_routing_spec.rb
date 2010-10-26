require 'spec_helper'

describe Admin::StatsController do
  
  it { should route(:get, "admin/stats").to(:action => :index) }
  
end