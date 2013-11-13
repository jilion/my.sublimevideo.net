require 'spec_helper'

describe Admin::MailsController do

  context "with logged in admin with the god role" do
    before do
      @admin = authenticated_admin(roles: ['god'])
      sign_in :admin, @admin
    end

    it "should assign mail logs array as @mail_logs and mail templates array as @mail_templates and render :index on GET :index" do
      MailLog.stub_chain(:all, :by_date, :page) { [mock_mail_log] }
      MailTemplate.stub_chain(:not_archived, :by_date, :page) { [mock_mail_template] }
      MailTemplate.stub_chain(:archived, :by_date, :page) { [mock_mail_template] }

      get :index
      expect(assigns(:mail_logs)).to eq [mock_mail_log]
      expect(assigns(:mail_templates)).to eq [mock_mail_template]
      expect(response).to be_success
      expect(response).to render_template(:index)
    end

    it "should assign mail log as @mail_log and render :new on GET :new" do
      allow(MailLog).to receive(:new) { mock_mail_log }

      get :new
      expect(assigns(:mail_log)).to eq mock_mail_log
      expect(response).to be_success
      expect(response).to render_template(:new)
    end

    it "should redirect to /admin/mails if create_and_deliver succeed on POST :create" do
      expect(Administration::EmailSender).to delay(:deliver_and_log, queue: 'my').with("template_id" => '1', "criteria" => "foo", "admin_id" => @admin.id)

      post :create, mail: { template_id: '1', criteria: "foo" }
      expect(response).to redirect_to(admin_mails_url)
    end
  end

  it_behaves_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: [:index, :new], post: :create }
  it_behaves_like "redirect when connected as", 'http://admin.test.host/sites', [[:admin, { roles: ['marcom'] }]], { get: [:index, :new], post: :create }

end
