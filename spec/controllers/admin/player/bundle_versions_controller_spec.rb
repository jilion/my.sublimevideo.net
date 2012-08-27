require 'spec_helper'

describe Admin::Player::BundleVersionsController do

  it_should_behave_like "redirect when connected as",
    'http://admin.test.host/login',
    [:authenticated_user, :guest],
    { get: [:index, :show], post: :create, delete: :destroy },
    bundle_id: 1

  it_should_behave_like "redirect when connected as",
    'http://admin.test.host/sites',
    [[:admin, { roles: ['marcom'] }]],
    { get: [:index, :show], post: :create, delete: :destroy },
    bundle_id: 1

end
