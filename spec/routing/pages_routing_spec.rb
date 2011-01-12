require 'spec_helper'

describe PagesController do

  %w[terms privacy].each do |page|
    it { should route(:get, page).to(:action => :show, :page => page) }
  end

end
