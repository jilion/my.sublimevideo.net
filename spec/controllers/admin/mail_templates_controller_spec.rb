require 'spec_helper'

describe Admin::MailTemplatesController do

  context "with logged in admin with the god role" do
    before do
      sign_in :admin, authenticated_admin(roles: ['god'])
      MailTemplate.stub(:find).with('1') { mock_mail_template }
    end

    it "should render :new on GET :new" do
      get :new
      response.should be_success
      response.should render_template(:new)
    end

    describe "POST :create" do
      before { MailTemplate.stub(:new) { mock_mail_template } }

      it "responds with redirect when save succeed" do
        mock_mail_template.stub(:save) { true }

        post :create, mail_template: { title: 'AAA', subject: 'BBB', body: 'CCC' }
        response.should redirect_to(admin_mails_path)
      end

      it "responds with success when save fails" do
        mock_mail_template.stub(:save) { false }
        mock_mail_template.stub(:errors) { ["error"] }

        post :create, mail_template: { title: 'AAA', subject: 'BBB', body: 'CCC' }
        response.should be_success
        response.should render_template(:new)
      end
    end

    it "should render :edit on GET :edit" do
      get :edit, id: '1'
      response.should be_success
      response.should render_template(:edit)
    end

    describe "PUT :update" do
      it "responds with redirect when update succeed" do
        mock_mail_template.stub(:update) { true }

        put :update, id: '1', mail_template: { title: 'AAA', subject: 'BBB', body: 'CCC' }
        response.should redirect_to(edit_admin_mail_template_path(mock_mail_template.id))
      end

      it "responds with success when update fails" do
        mock_mail_template.stub(:update) { false }
        mock_mail_template.stub(:errors) { ["error"] }

        put :update, id: '1', mail_template: { title: 'AAA', subject: 'BBB', body: 'CCC' }
        response.should be_success
        response.should render_template(:edit)
      end
    end
  end

  it_should_behave_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: :edit, put: :update }
  it_should_behave_like "redirect when connected as", 'http://admin.test.host/sites', [[:admin, { roles: ['marcom'] }]], { get: :edit, put: :update }

end
