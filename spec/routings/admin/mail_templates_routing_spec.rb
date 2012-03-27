require 'spec_helper'

describe Admin::MailTemplatesController do

  it { get(with_subdomain('admin', 'mails/templates/new')).should    route_to('admin/mail_templates#new') }
  it { post(with_subdomain('admin', 'mails/templates')).should       route_to('admin/mail_templates#create') }
  it { get(with_subdomain('admin', 'mails/templates/1/edit')).should route_to('admin/mail_templates#edit', id: '1') }
  it { put(with_subdomain('admin', 'mails/templates/1')).should      route_to('admin/mail_templates#update', id: '1') }

end
