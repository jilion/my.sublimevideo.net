require 'spec_helper'

describe My::PagesController do

  %w[terms privacy help].each do |page|
    it { get(with_subdomain('my', page)).should route_to('my/pages#show', page: page) }
  end

end
