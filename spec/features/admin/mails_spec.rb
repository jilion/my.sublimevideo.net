require 'spec_helper'

feature "Mails index" do

  describe "With no logs and no templates" do
    background do
      sign_in_as :admin, roles: ['god']
    end

    scenario "should be 0 template and 0 log created" do
      MailTemplate.should be_empty
      MailLog.should be_empty
    end

    scenario "should have text instead of tables if no templates or no logs exist" do
      go 'admin', 'mails'

      page.should have_css 'div#mail_logs_table_wrap'
      page.should have_no_css 'table#mail_logs'
      page.should have_css 'div#mail_templates_table_wrap'
      page.should have_no_css 'table#mail_templates'

      page.should have_content "No mail sent yet!"
      page.should have_content "No mail templates yet!"
    end
  end

  describe "With logs and templates" do
    background do
      sign_in_as :admin, roles: ['god']
      @mail_log      = create(:mail_log, admin_id: @current_admin.id)
      @mail_template = @mail_log.template
    end

    scenario "should be 1 template and 1 log created" do
      MailTemplate.should have(1).item
      MailLog.should have(1).item
    end

    scenario "should have a table containing mail logs and a table containing mail templates" do
      go 'admin', 'mails'

      page.should have_css 'div#mail_logs_table_wrap'
      page.should have_css 'table#mail_logs'

      page.should have_css 'div#mail_templates_table_wrap'
      page.should have_css 'table#mail_templates'

      page.should have_content @mail_log.admin.email
      page.should have_content @mail_log.template.title
      page.should have_content @mail_log.user_ids.size.to_s

      page.should have_content @mail_template.title
      page.should have_content @mail_template.subject
      page.should have_content "{{user.name}} ({{user.email}})"
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

      page.should have_content "Send an email"
      ActionMailer::Base.deliveries.should be_empty
      Sidekiq::Worker.clear_all

      select "##{@mail_template.id} - #{@mail_template.title}", from: "Choose a template (very carefully)"
      select "Not Archived (1)", from: "mail[criteria]"

      click_button 'Preview email'

      current_url.should eq "http://admin.sublimevideo.dev/mails/confirm"

      click_button 'I have triple checked, and want to send this email'

      page.should have_content "Sending in progress..."

      Sidekiq::Worker.drain_all
      ActionMailer::Base.deliveries.should have(1).item

      latest_log = MailLog.by_date.first
      latest_log.template_id.should eq @mail_template.id
      latest_log.admin_id.should eq @current_admin.id
      latest_log.snapshot.should eq @mail_template.snapshotize
      latest_log.criteria.should eq "not_archived"
    end
  end

end
