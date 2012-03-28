require 'spec_helper'

describe PagesController do

  # Rails issue with advanced constraint https://github.com/dchelimsky/rspec-rails/issues/5
  # %w[terms privacy help].each do |page|
  #   it { get(with_subdomain('my', page)).should route_to('pages#show', page: page) }
  # end

end
