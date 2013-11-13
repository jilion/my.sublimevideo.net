require 'spec_helper'

describe Admin::MailLogsController do

  it { expect(get(with_subdomain('admin', 'mails/logs/1'))).to route_to('admin/mail_logs#show', id: '1') }

end
