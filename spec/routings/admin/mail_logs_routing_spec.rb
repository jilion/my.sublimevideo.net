require 'spec_helper'

describe Admin::MailLogsController do

  it { get(with_subdomain('admin', 'mails/logs/1')).should route_to('admin/mail_logs#show', id: '1') }

end
