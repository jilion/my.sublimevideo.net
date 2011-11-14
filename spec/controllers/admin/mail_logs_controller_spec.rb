require 'spec_helper'

describe Admin::MailLogsController do

  context "with logged in admin" do
    before(:each) { sign_in :admin, authenticated_admin }

    it "responds with success to GET :show" do
      MailLog.stub(:find).with("1") { mock_mail_log }

      get :show, id: '1'
      response.should be_success
      response.should render_template(:show)
    end
  end

  it_should_behave_like "redirect when connected as", '/login', [:user, :guest], { get: :show }

end