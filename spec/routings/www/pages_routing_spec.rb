require 'spec_helper'

describe Www::PagesController do

  it { get(with_subdomain('www', '/')).should route_to('www/pages#show', page: 'home') }
  %w[features plans demo customer-showcase vision contact].each do |page|
    it { get(with_subdomain('www', page)).should route_to('www/pages#show', page: page) }
  end

end
