require 'spec_helper'

describe Admin::InvoicesController do

  it_behaves_like "redirect when connected as", 'http://admin.test.host/login', [:user, :guest], { get: [:index, :edit], post: :retry_charging }
  it_behaves_like "redirect when connected as", 'http://admin.test.host/sites', [[:admin, { roles: ['marcom'] }]], { get: [:index, :edit], post: :retry_charging }

end
