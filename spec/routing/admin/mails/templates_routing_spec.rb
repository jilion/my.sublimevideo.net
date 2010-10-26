require 'spec_helper'

describe Admin::Mails::TemplatesController do
  
  it { should route(:get, "admin/mails/templates/1/edit").to(:action => :edit, :id => "1") }
  it { should route(:put, "admin/mails/templates/1").to(:action => :update, :id => "1") }
  
end