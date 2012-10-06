require 'spec_helper'

describe Admin::App::ComponentVersionsController do

  it { get(with_subdomain('admin', 'app/components/e/versions')).should route_to('admin/app/component_versions#index', component_id: 'e') }
  it { get(with_subdomain('admin', 'app/components/e/versions/1')).should route_to('admin/app/component_versions#show', component_id: 'e',  id: '1') }
  it { post(with_subdomain('admin', 'app/components/e/versions')).should route_to('admin/app/component_versions#create', component_id: 'e') }
  it { delete(with_subdomain('admin', 'app/components/e/versions/1')).should route_to('admin/app/component_versions#destroy', component_id: 'e', id: '1') }

end
