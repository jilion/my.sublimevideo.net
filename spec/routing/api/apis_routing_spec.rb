require 'spec_helper'

describe Api::ApisController do

  # legacy routes
  it { get(with_subdomain('my', 'api/test_request')).should route_to('api/apis#test_request') }
  it { get(with_subdomain('my', 'api/sites.json')).should route_to('api/sites#index', format: 'json') }
  it { get(with_subdomain('my', 'api/sites.xml')).should route_to('api/sites#index', format: 'xml') }
  it { get(with_subdomain('my', 'api/sites/1.json')).should route_to('api/sites#show', id: '1', format: 'json') }
  it { get(with_subdomain('my', 'api/sites/1.xml')).should route_to('api/sites#show', id: '1', format: 'xml') }
  it { get(with_subdomain('my', 'api/sites/1/usage.json')).should route_to('api/sites#usage', id: '1', format: 'json') }
  it { get(with_subdomain('my', 'api/sites/1/usage.xml')).should route_to('api/sites#usage', id: '1', format: 'xml') }

  it { get(with_subdomain('api', 'test_request')).should route_to('api/apis#test_request') }
  it { get(with_subdomain('api', 'sites.json')).should route_to('api/sites#index', format: 'json') }
  it { get(with_subdomain('api', 'sites.xml')).should route_to('api/sites#index', format: 'xml') }
  it { get(with_subdomain('api', 'sites/1.json')).should route_to('api/sites#show', id: '1', format: 'json') }
  it { get(with_subdomain('api', 'sites/1.xml')).should route_to('api/sites#show', id: '1', format: 'xml') }
  it { get(with_subdomain('api', 'sites/1/usage.json')).should route_to('api/sites#usage', id: '1', format: 'json') }
  it { get(with_subdomain('api', 'sites/1/usage.xml')).should route_to('api/sites#usage', id: '1', format: 'xml') }

end
