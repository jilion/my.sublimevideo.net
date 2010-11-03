require 'spec_helper'

describe Admin::MailLogsController do
  
  it { should route(:get, "admin/mails/logs/1").to(:action => :show, :id => "1") }
  
end