require 'spec_helper'

describe Admin::MailTemplatesController do

  it { { get:  'admin/mails/templates/new' }.should    route_to(controller: 'admin/mail_templates', action: 'new') }
  it { { post: 'admin/mails/templates' }.should        route_to(controller: 'admin/mail_templates', action: 'create') }
  it { { get:  'admin/mails/templates/1/edit' }.should route_to(controller: 'admin/mail_templates', action: 'edit', id: '1') }
  it { { put:  'admin/mails/templates/1' }.should      route_to(controller: 'admin/mail_templates', action: 'update', id: '1') }

end
