require 'spec_helper'

describe Admin::MailsController do

  it { should route(:get,  "admin/mails").to(:action => :index) }
  it { should route(:get,  "admin/mails/new").to(:action => :new) }
  it { should route(:post, "admin/mails").to(:action => :create) }

end
