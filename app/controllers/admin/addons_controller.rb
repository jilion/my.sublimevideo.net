class Admin::AddonsController < Admin::AdminController
  
  def index
    @addons = Addon.all
  end
  
end