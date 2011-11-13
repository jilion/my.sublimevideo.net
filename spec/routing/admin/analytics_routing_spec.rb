require 'spec_helper'

describe Admin::AnalyticsController do
  
  it { should route(:get,  "/admin/analytics").to(:controller => "admin/analytics", :action => :index) }
  it { should route(:get,  "/admin/analytics/enthusiasts_total_evolution").to(:controller => "admin/analytics", :action => :show, :report => 'enthusiasts_total_evolution') }
  it { should route(:get,  "/admin/analytics/enthusiasts_information").to(:controller => "admin/analytics", :action => :show, :report => 'enthusiasts_information') }
  
end