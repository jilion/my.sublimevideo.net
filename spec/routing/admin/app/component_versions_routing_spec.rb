require 'spec_helper'

describe Admin::App::ComponentVersionsController do

  it { expect(get(with_subdomain('admin', 'app/components/e/versions'))).to route_to('admin/app/component_versions#index', component_id: 'e') }
  it { expect(get(with_subdomain('admin', 'app/components/e/versions/1'))).to route_to('admin/app/component_versions#show', component_id: 'e',  id: '1') }
  it { expect(post(with_subdomain('admin', 'app/components/e/versions'))).to route_to('admin/app/component_versions#create', component_id: 'e') }
  it { expect(delete(with_subdomain('admin', 'app/components/e/versions/1'))).to route_to('admin/app/component_versions#destroy', component_id: 'e', id: '1') }

end
