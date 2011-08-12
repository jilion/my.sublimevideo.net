require 'spec_helper'

describe PagesController do

  %w[terms privacy].each do |page|
    it { { get: page }.should route_to(controller: 'pages', action: 'show', page: page) }
  end

end
