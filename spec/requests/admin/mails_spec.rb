require 'spec_helper'

feature "Mails index" do

  describe "With no logs and no templates" do
    background do
      sign_in_as :admin
    end

    scenario "should be 0 template and 0 log created" do
      MailTemplate.all.should be_empty
      MailLog.all.should be_empty
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
      sign_in_as :admin
      @mail_log      = Factory.create(:mail_log, admin_id: @current_admin.id)
      @mail_template = @mail_log.template
    end

    scenario "should be 1 template and 1 log created" do
      MailTemplate.all.should have(1).item
      MailLog.all.should have(1).item
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
      page.should have_content "Hi {{user.name}}"
    end
  end

end

feature "Mails sending" do

  background do
    @user = Factory.create(:user)
    sign_in_as :admin
    @mail_template = Factory.create(:mail_template)
  end

  context "choosing 'all' criteria" do
    background do
      User.stub_chain(:with_activity).and_return { [@user] }
      ActionMailer::Base.deliveries.clear
    end

    scenario "should be possible to send an email from a template to a selection of users" do
      go 'admin', 'mails/new'

      page.should have_content "Send a mail"
      ActionMailer::Base.deliveries.should be_empty

      select @mail_template.title, from: "Template"
      select "all", from: "Criteria"
      click_button "Send mail"

      current_url.should eq "http://admin.sublimevideo.dev/mails"

      page.should have_content "Sending in progress..."

      Delayed::Job.where { handler =~ "%deliver_and_log%" }.should have(1).item
      @worker.work_off
      ActionMailer::Base.deliveries.should have(1).item

      latest_log = MailLog.by_date.first
      latest_log.template_id.should eq @mail_template.id
      latest_log.admin_id.should eq @current_admin.id
      latest_log.snapshot.should eq @mail_template.snapshotize
      latest_log.criteria.should eq "all"
    end
  end

end
