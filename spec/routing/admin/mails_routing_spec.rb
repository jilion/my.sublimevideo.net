require 'spec_helper'

describe Admin::MailsController do

  it { get(with_subdomain('admin', 'mails')).should     route_to('admin/mails#index') }
  it { get(with_subdomain('admin', 'mails/new')).should route_to('admin/mails#new') }
  it { post(with_subdomain('admin', 'mails')).should    route_to('admin/mails#create') }

end
