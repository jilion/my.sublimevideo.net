class Admin::RegistrationsController < Devise::RegistrationsController
  before_filter :authenticate_admin!
  respond_to :html
  layout 'admin'
end