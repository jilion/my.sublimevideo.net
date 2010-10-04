require 'spec_helper'

describe Admin::MailsController do
  
  it { should route(:get, "admin/mails").to(:action => :index) }
  
end