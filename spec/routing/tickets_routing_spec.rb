require "spec_helper"

describe TicketsController do

  it { should route(:get, "/support").to(:action => "new") }
  it { should route(:post, "/support").to(:action => "create") }
  # it { { :put => "/support/1" }.should_not be_routable }
  # it { { :delete => "/support/1" }.should_not be_routable }

end
