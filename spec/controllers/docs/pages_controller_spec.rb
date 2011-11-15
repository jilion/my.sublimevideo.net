require 'spec_helper'

describe Docs::PagesController do

  context "as guest" do
    %w[quickstart-guide javascript-api/usage].each do |page|
      it "responds with success to GET :show, on #{page} page" do
        get :show, page: page
        response.should render_template("docs/pages/#{page}")
      end
    end
  end

end
