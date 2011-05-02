require 'spec_helper'

feature "Checks" do
  background do
    sign_in_as :user
  end

  scenario "redirect feedback" do
    visit "/feedback"
    current_url.should =~ %r(http://[^/]+/support)
  end
end

feature "Support" do
  background do
    sign_in_as :user
    visit "/support"
  end

  scenario "navigation" do
    click_link "Support"
    current_url.should =~ %r(http://[^/]+/support)
  end

  describe "new" do
    scenario "submit a valid ticket" do

      select "Bug report", :from => "ticket_type"
      fill_in "Subject", :with => "I have a request!"
      fill_in "Message", :with => "I have a request this is a long text!"
      click_button "Send"

      page.should have_content I18n.t('flash.tickets.create.notice')

      Delayed::Job.last.name.should == 'Ticket#post_ticket'
      VCR.use_cassette("ticket/post_ticket_standard_support") { @worker.work_off }
      Delayed::Job.last.should be_nil
      @current_user.reload.zendesk_id.should be_present
    end

    scenario "submit a ticket with an invalid type" do
      select "Choose a category", :from => "ticket_type"
      fill_in "Subject", :with => "I have a request!"
      fill_in "Message", :with => "I have a request this is a long text!"
      click_button "Send"

      current_url.should =~ %r(http://[^/]+/support)
      page.should have_content "You must choose a category"
      page.should have_no_content I18n.t('flash.tickets.create.notice')
      Delayed::Job.last.should_not == 'Ticket#post_ticket'
    end

    scenario "submit a ticket with an invalid subject" do
      select "Feature request / Improvement suggestion", :from => "ticket_type"
      fill_in "Subject", :with => ""
      fill_in "Message", :with => "I have a request this is a long text!"
      click_button "Send"

      current_url.should =~ %r(http://[^/]+/support)
      page.should have_content "Subject can't be blank"
      page.should have_no_content I18n.t('flash.tickets.create.notice')
      Delayed::Job.last.should_not == 'Ticket#post_ticket'
    end

    scenario "submit a ticket with an invalid message" do
      select "Feature request / Improvement suggestion", :from => "ticket_type"
      fill_in "Subject", :with => "I have a request!"
      fill_in "Message", :with => ""
      click_button "Send"

      current_url.should =~ %r(http://[^/]+/support)
      page.should have_content "Message can't be blank"
      page.should have_no_content I18n.t('flash.tickets.create.notice')
      Delayed::Job.last.should_not == 'Ticket#post_ticket'
    end
  end

end
