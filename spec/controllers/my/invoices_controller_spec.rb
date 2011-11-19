require 'spec_helper'

describe My::InvoicesController do

  it_should_behave_like "redirect when connected as", 'http://my.test.host/suspended', [[:user, { state: 'suspended' }]], { get: :index }, site_id: '1'
  it_should_behave_like "redirect when connected as", 'http://test.host/', [:guest], { get: :index, put: :retry }, site_id: '1'
  it_should_behave_like "redirect when connected as", 'http://test.host/', [:guest], { get: :show }

end