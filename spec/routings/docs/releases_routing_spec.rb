require 'spec_helper'

describe Docs::ReleasesController do

  it { get(with_subdomain('docs', 'releases')).should route_to('docs/releases#index') }

end
