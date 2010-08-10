require 'spec_helper'

describe PagesController do
  
  %w[terms docs suspended].each do |page|
    it { should route(:get, page).to(:action => :show, :page => page) }
  end
  
end