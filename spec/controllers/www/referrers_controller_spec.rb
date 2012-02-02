require 'spec_helper'

describe Www::ReferrersController do

  describe "GET redirect" do

    it "should update or create referrer from type" do
      controller.request.stub(:referer).and_return('http://www.domain.com')
      Referrer.should_receive(:create_or_update_from_type!).with('nln2ofdf', 'http://www.domain.com', 'c')
      get :redirect, token: 'nln2ofdf', type: 'c'
    end

    it "should redirect from" do
      Referrer.stub(:create_or_update_from_type!)
      get :redirect, token: 'nln2ofdf', type: 'c'
      response.should redirect_to("http://test.host/")
    end

  end

end
