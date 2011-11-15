require 'spec_helper'

describe Docs::PagesController do

  it { get(with_subdomain('docs', 'quickstart-guide')).should route_to('docs/pages#show', page: 'quickstart-guide') }
  it { get(with_subdomain('docs', 'javascript-api/usage')).should route_to('docs/pages#show', page: 'javascript-api/usage') }

end
