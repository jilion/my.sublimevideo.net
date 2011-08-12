require 'spec_helper'

describe Admin::MailLogsController do

  it { { get: 'admin/mails/logs/1' }.should route_to(controller: 'admin/mail_logs', action: 'show', id: '1') }

end
