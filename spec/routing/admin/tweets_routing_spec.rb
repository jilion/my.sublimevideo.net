require 'spec_helper'

describe Admin::TweetsController do

  it { should route(:get, "admin/tweets").to(:action => :index) }
  it { should route(:put, "admin/tweets/1/favorite").to(:action => :favorite, :id => "1") }

end
