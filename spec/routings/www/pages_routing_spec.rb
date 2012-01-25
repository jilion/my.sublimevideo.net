require 'spec_helper'

describe Www::PagesController do

  it { get(with_subdomain('www', '/')).should route_to('www/pages#show', page: 'home', format: :html) }

  # Rails issue with advanced constraint https://github.com/dchelimsky/rspec-rails/issues/5
  # %w[features plans demo customer-showcase contact].each do |page|
  #   it { get(with_subdomain('www', page)).should route_to('www/pages#show', page: page) }
  # end

end
