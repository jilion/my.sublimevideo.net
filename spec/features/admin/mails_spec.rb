require 'spec_helper'

feature "Mails index" do

  describe "With no logs and no templates" do
    background do
      sign_in_as :admin, roles: ['god']
    end

    scenario "should be 0 template and 0 log created" do
      expect(MailTemplate.all).to be_empty
      expect(MailLog.all).to be_empty
    end

    scenario "should have text instead of tables if no templates or no logs exist" do
      go 'admin', 'mails'

      expect(page).to have_css 'div#mail_logs_table_wrap'
      expect(page).to have_no_css 'table#mail_logs'
      expect(page).to have_css 'div#mail_templates_table_wrap'
      expect(page).to have_no_css 'table#mail_templates'

      expect(page).to have_content "No mail sent yet!"
      expect(page).to have_content "No mail templates yet!"
    end
  end

  describe "With logs and templates" do
    background do
      sign_in_as :admin, roles: ['god']
      @mail_log      = create(:mail_log, admin_id: @current_admin.id)
      @mail_template = @mail_log.template
    end

    scenario "should be 1 template and 1 log created" do
      expect(MailTemplate.count).to eq(1)
      expect(MailLog.count).to eq(1)
    end

    scenario "should have a table containing mail logs and a table containing mail templates" do
      go 'admin', 'mails'

      expect(page).to have_css 'div#mail_logs_table_wrap'
      expect(page).to have_css 'table#mail_logs'

      expect(page).to have_css 'div#mail_templates_table_wrap'
      expect(page).to have_css 'table#mail_templates'

      expect(page).to have_content @mail_log.admin.email
      expect(page).to have_content @mail_log.template.title
      expect(page).to have_content @mail_log.user_ids.size.to_s

      expect(page).to have_content @mail_template.title
      expect(page).to have_content @mail_template.subject
      expect(page).to have_content "{{user.name}} ({{user.email}})"
    end
  end

end

feature "Mails sending" do

  context "choosing the 'Not Archived' criteria" do
    background do
      @user = create(:user)
      Sidekiq::Worker.clear_all
      sign_in_as :admin, roles: ['god']
      @mail_template = create(:mail_template)
      ActionMailer::Base.deliveries.clear
    end

    scenario "it's possible to send an email from a template to a selection of users" do
      go 'admin', 'mails/new'

      expect(page).to have_content "Send an email"
      expect(ActionMailer::Base.deliveries).to be_empty
      Sidekiq::Worker.clear_all

      select "##{@mail_template.id} - #{@mail_template.title}", from: "Choose a template (very carefully)"
      select "Not Archived (1)", from: "mail[criteria]"

      click_button 'Preview email'

      expect(current_url).to eq "http://admin.sublimevideo.dev/mails/confirm"

      click_button 'I have triple checked, and want to send this email'

      expect(page).to have_content "Sending in progress..."

      Sidekiq::Worker.drain_all
      expect(ActionMailer::Base.deliveries.size).to eq(1)

      latest_log = MailLog.by_date.first
      expect(latest_log.template_id).to eq @mail_template.id
      expect(latest_log.admin_id).to eq @current_admin.id
      expect(latest_log.snapshot).to eq @mail_template.snapshotize
      expect(latest_log.criteria).to eq "not_archived"
    end
  end

end
