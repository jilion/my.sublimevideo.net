require "spec_helper"

describe TicketsController do
  describe "routing" do
    
    it "recognizes and generates #new" do
      { :get => "/support" }.should route_to(:controller => "tickets", :action => "new")
    end
    
    it "recognizes and generates #create" do
      { :post => "/support" }.should route_to(:controller => "tickets", :action => "create")
    end
    
  end
end
