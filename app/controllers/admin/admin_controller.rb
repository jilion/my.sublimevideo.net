class Admin::AdminController < ApplicationController
  before_filter :authenticate_admin!
  respond_to :html
  layout 'admin'
end