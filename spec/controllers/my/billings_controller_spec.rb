require 'spec_helper'

describe My::BillingsController do

  it_should_behave_like "redirect when connected as", '/login', [:guest], { get: :edit, put: :update }

end
