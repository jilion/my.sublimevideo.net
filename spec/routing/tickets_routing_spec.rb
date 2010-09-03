require "spec_helper"

describe TicketsController do
  describe "routing" do
    
    it "recognizes and generates #new" do
      { :get => "/feedback" }.should route_to(:controller => "tickets", :action => "new")
    end
    
    it "recognizes and generates #create" do
      { :post => "/feedback" }.should route_to(:controller => "tickets", :action => "create")
    end
    
  end
end
