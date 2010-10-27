require 'spec_helper'

describe Admin::Mails::LogsController do
  
  it { should route(:get, "admin/mails/logs/1").to(:action => :show, :id => "1") }
  
end