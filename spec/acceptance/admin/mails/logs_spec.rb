require 'spec_helper'

include ActionView::Helpers::TagHelper
include ActionView::Helpers::TextHelper

feature "Mail logs show:" do
  let(:mail_log) { Factory(:mail_log) }
  
  background do
    sign_in_as :admin
    Factory(:user)
  end
  
  scenario "should be possible to show mail log" do
    visit "/admin/mails/logs/#{mail_log.id}"
    
    page.should have_content(mail_log.admin.email)
    page.should have_content(mail_log.template.title)
    page.should have_content(mail_log.template.subject)
    mail_log.template.body.split("\n").each do |body_parts|
      page.should have_content(body_parts)
    end
    
    page.should have_content(mail_log.admin_id.to_s)
    page.should have_content(mail_log.template_id.to_s)
    page.should have_content(mail_log.criteria.inspect)
  end
end