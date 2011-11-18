require 'spec_helper'

describe My::BillingsController do

  it_should_behave_like "redirect when connected as", 'http://test.host/', [:guest], { get: :edit, put: :update }

end
