require 'spec_helper'

describe Admin::MailTemplatesController do

  context "with logged in admin with the god role" do
    before do
      sign_in :admin, authenticated_admin(roles: ['god'])
      allow(MailTemplate).to receive(:find).with('1') { mock_mail_template }
    end

    it "should render :new on GET :new" do
      get :new
      expect(response).to be_success
      expect(response).to render_template(:new)
    end

    describe "POST :create" do
      before { allow(MailTemplate).to receive(:new) { mock_mail_template } }

      it "responds with redirect when save succeed" do
        allow(mock_mail_template).to receive(:save) { true }

        post :create, mail_template: { title: 'AAA', subject: 'BBB', body: 'CCC' }
        expect(response).to redirect_to(admin_mails_path)
      end

      it "responds with success when save fails" do
        allow(mock_mail_template).to receive(:save) { false }
        allow(mock_mail_template).to receive(:errors) { ["error"] }

        post :create, mail_template: { title: 'AAA', subject: 'BBB', body: 'CCC' }
        expect(response).to be_success
        expect(response).to render_template(:new)
      end
    end

    it "should render :edit on GET :edit" do
      get :edit, id: '1'
      expect(response).to be_success
      expect(response).to render_template(:edit)
    end

    describe "PUT :update" do
      it "responds with redirect when update succeed" do
        allow(mock_mail_template).to receive(:update) { true }

        put :update, id: '1', mail_template: { title: 'AAA', subject: 'BBB', body: 'CCC' }
        expect(response).to redirect_to(edit_admin_mail_template_path(mock_mail_template.id))
      end

      it "responds with success when update fails" do
        allow(mock_mail_template).to receive(:update) { false }
        allow(mock_mail_template).to receive(:errors) { ["error"] }

        put :update, id: '1', mail_template: { title: 'AAA', subject: 'BBB', body: 'CCC' }
        expect(response).to be_success
        expect(response).to render_template(:edit)
      end
    end
  end

  it_behaves_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: :edit, put: :update }
  it_behaves_like "redirect when connected as", 'http://admin.test.host/sites', [[:admin, { roles: ['marcom'] }]], { get: :edit, put: :update }

end
