class AdminController < ApplicationController
  responders Responders::FlashResponder

  before_filter :authenticate_admin!

  layout 'admin'
end
