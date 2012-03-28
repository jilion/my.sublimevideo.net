require 'spec_helper'

describe BillingsController do

  it_should_behave_like "redirect when connected as", 'http://my.test.host/login', [:guest], { get: :edit, put: :update }

end
