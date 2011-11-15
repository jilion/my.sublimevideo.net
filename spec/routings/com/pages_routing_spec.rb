require 'spec_helper'

describe Com::PagesController do

  it { get('/').should route_to('com/pages#show', page: 'home') }
  it { get('demo').should route_to('com/pages#show', page: 'demo') }
  it { get('features').should route_to('com/pages#show', page: 'features') }
  it { get('plans').should route_to('com/pages#show', page: 'plans') }

end
