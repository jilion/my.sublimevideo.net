require 'spec_helper'

describe Admin::MailsController do

  it { expect(get(with_subdomain('admin', 'mails'))).to     route_to('admin/mails#index') }
  it { expect(get(with_subdomain('admin', 'mails/new'))).to route_to('admin/mails#new') }
  it { expect(post(with_subdomain('admin', 'mails'))).to    route_to('admin/mails#create') }

end
