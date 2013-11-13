require 'spec_helper'

describe Admin::MailTemplatesController do

  it { expect(get(with_subdomain('admin', 'mails/templates/new'))).to    route_to('admin/mail_templates#new') }
  it { expect(post(with_subdomain('admin', 'mails/templates'))).to       route_to('admin/mail_templates#create') }
  it { expect(get(with_subdomain('admin', 'mails/templates/1/edit'))).to route_to('admin/mail_templates#edit', id: '1') }
  it { expect(put(with_subdomain('admin', 'mails/templates/1'))).to      route_to('admin/mail_templates#update', id: '1') }

end
