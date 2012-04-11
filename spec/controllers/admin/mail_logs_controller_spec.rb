require 'spec_helper'

describe Admin::MailLogsController do

  context "with logged in admin with the god role" do
    before { sign_in :admin, authenticated_admin(roles: ['god']) }

    it "responds with success to GET :show" do
      MailLog.stub(:find).with("1") { mock_mail_log }

      get :show, id: '1'
      response.should be_success
      response.should render_template(:show)
    end
  end

  it_should_behave_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: :show }
  it_should_behave_like "redirect when connected as", 'http://admin.test.host/sites', [[:admin, { roles: ['marcom'] }]], { get: :show }

end