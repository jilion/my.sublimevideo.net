require 'spec_helper'

describe Com::PagesController do

  it { get('/').should route_to('com/pages#show', page: 'home') }
  %w[features plans demo customer-showcases help vision contact].each do |page|
    it { get(page).should route_to('com/pages#show', page: page) }
  end

end
