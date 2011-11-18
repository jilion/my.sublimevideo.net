require 'spec_helper'

describe My::Users::PasswordsController do

  it_should_behave_like "redirect when connected as", 'http://test.host/', :guest, { post: :validate }

end
