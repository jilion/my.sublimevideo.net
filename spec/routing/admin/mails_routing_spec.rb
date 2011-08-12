require 'spec_helper'

describe Admin::MailsController do

  it { { get:  'admin/mails' }.should     route_to(controller: 'admin/mails', action: 'index') }
  it { { get:  'admin/mails/new' }.should route_to(controller: 'admin/mails', action: 'new') }
  it { { post: 'admin/mails' }.should     route_to(controller: 'admin/mails', action: 'create') }

end
