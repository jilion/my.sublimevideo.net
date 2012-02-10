require 'spec_helper'

describe Www::ReferrersController do

  describe "GET redirect" do
    before(:each) do
      Factory.create(:site, token: 'nln2ofdf')
    end

    context "referer is present" do
      it "updates or creates referrer from type" do
        controller.request.stub(:referer).and_return('http://www.domain.com')

        expect { get :redirect, token: 'nln2ofdf', type: 'c' }.to change(Referrer.where(url: 'http://www.domain.com'), :count).by(1)
      end
    end

    context "referer is not present" do
      it "doesn't save referer successfully but doesn't throw an error" do
        controller.request.stub(:referer).and_return('')

        expect { get :redirect, token: 'nln2ofdf', type: 'c' }.to_not change(Referrer, :count)
      end
    end

    it "redirects to root" do
      Referrer.stub(:create_or_update_from_type)
      get :redirect, token: 'nln2ofdf', type: 'c'

      response.should redirect_to("http://test.host/")
    end

  end

end
