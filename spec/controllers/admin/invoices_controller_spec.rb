require 'spec_helper'

describe Admin::InvoicesController do

  it_should_behave_like "redirect when connected as", '/admin/login', [:user, :guest], { get: [:index, :edit], post: :retry_charging }

end
