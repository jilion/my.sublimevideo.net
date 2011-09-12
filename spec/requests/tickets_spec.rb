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
  context "user has only the 'forum' support level" do
    background do
      sign_in_as :user
      FactoryGirl.create(:site, user: @current_user, plan_id: @free_plan.id)
      visit "/support"
    end

    scenario "navigation" do
      click_link "Support"
      current_url.should =~ %r(http://[^/]+/support)
    end

    describe "new" do
      scenario "doesn't have access to all ticket types" do
        page.should have_no_content('Integration question')
      end

      scenario "doesn't have access to the form" do
        page.should have_no_content('use the form below')
        page.should have_no_selector('form.new_ticket')
      end
    end
  end

  context "user has the 'email' support level" do
    background do
      sign_in_as :user
      FactoryGirl.create(:site, user: @current_user, plan_id: @paid_plan.id)
      visit "/support"
    end

    scenario "navigation" do
      click_link "Support"
      current_url.should =~ %r(http://[^/]+/support)
    end

    describe "new", :focus => true do
      scenario "has access to all ticket types" do
        page.should have_content('Integration question')
      end

      scenario "has access to the form" do
        page.should have_content('use the form below')
        page.should have_selector('form.new_ticket')
      end

      scenario "submit a valid ticket" do
        select "Bug report", :from => "ticket_type"
        fill_in "Subject", :with => "I have a request!"
        fill_in "Message", :with => "I have a request this is a long text!"
        expect { click_button "Send" }.to change(Delayed::Job.where(:handler.matches => "%post_ticket%"), :count).by(1)

        page.should have_content I18n.t('flash.tickets.create.notice')

        VCR.use_cassette("ticket/post_ticket") do
          expect { @worker.work_off }.to change(Delayed::Job.where(:handler.matches => "%post_ticket%"), :count).by(-1)
        end
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
        Delayed::Job.last.should_not == 'Class#post_ticket'
      end

      scenario "submit a ticket with an invalid subject" do
        select "Feature request / Improvement suggestion", :from => "ticket_type"
        fill_in "Subject", :with => ""
        fill_in "Message", :with => "I have a request this is a long text!"
        click_button "Send"

        current_url.should =~ %r(http://[^/]+/support)
        page.should have_content "Subject can't be blank"
        page.should have_no_content I18n.t('flash.tickets.create.notice')
        Delayed::Job.last.should_not == 'Class#post_ticket'
      end

      scenario "submit a ticket with an invalid message" do
        select "Feature request / Improvement suggestion", :from => "ticket_type"
        fill_in "Subject", :with => "I have a request!"
        fill_in "Message", :with => ""
        click_button "Send"

        current_url.should =~ %r(http://[^/]+/support)
        page.should have_content "Message can't be blank"
        page.should have_no_content I18n.t('flash.tickets.create.notice')
        Delayed::Job.last.should_not == 'Class#post_ticket'
      end
    end
  end

end
