require 'spec_helper'

describe Www::PressReleasesController do

  it { get(with_subdomain('www', '/pr/2011-12-6')).should route_to('www/press_releases#show', page: '2011-12-6') }

end
