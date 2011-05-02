require 'spec_helper'

describe Users::PasswordsController do

  it_should_behave_like "redirect when connected as", '/login', :guest, { :post => :validate }

end