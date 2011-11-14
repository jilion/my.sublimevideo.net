require 'spec_helper'

describe BillingsController do

  it_should_behave_like "redirect when connected as", '/login', [:guest], { get: :edit, put: :update }

end
