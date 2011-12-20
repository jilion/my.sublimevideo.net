require 'spec_helper'

describe My::BillingsController do

  it_should_behave_like "redirect when connected as", 'http://my.test.host/login', [:guest], { get: :edit, put: :update }

end
