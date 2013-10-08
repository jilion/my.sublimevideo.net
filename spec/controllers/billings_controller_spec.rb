require 'spec_helper'

describe BillingsController do

  it_behaves_like "redirect when connected as", 'http://my.test.host/login', [:guest], { get: :edit, put: :update }

end
