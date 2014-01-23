require 'spec_helper'

describe InvoicesController do

  it_behaves_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, { state: 'suspended' }]], { get: :index }, site_id: '1'
  it_behaves_like "redirect when connected as", 'http://my.test.host/login', [:guest], { get: :index }, site_id: '1'
  it_behaves_like "redirect when connected as", 'http://my.test.host/login', [:guest], { get: :show }

end
