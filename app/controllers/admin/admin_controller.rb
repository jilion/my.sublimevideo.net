class Admin::AdminController < ApplicationController
  respond_to :html

  skip_before_filter :authenticate_user!
  before_filter :authenticate_admin!

  layout 'admin'
end
