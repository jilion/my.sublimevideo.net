require 'spec_helper'

describe AddonsController do

  it_behaves_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, { state: 'suspended' }]], { get: :index }, site_id: '1'
  it_behaves_like "redirect when connected as", 'http://my.test.host/login', [:guest], { get: :index }, site_id: '1'
  it_behaves_like "redirect when connected as", 'http://my.test.host/login', [:guest], { get: :show }
  it_behaves_like "redirect when connected as", 'http://test.host/modular-player#stats', [:guest], { get: :show }, site_id: '1', id: 'stats', public: '1'

end
