require 'spec_helper'

describe ComsController do

  context "as guest" do
    %w[home demo features plans].each do |page|
      it "responds with success to GET :show, on #{page} page" do
        get :show, page: page
        response.should render_template("pages/#{page}")
      end
    end
  end

end
