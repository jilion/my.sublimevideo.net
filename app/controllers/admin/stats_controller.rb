class Admin::StatsController < Admin::AdminController
  respond_to :html
  respond_to :js, :only => :show

  def index
  end

  def show
    respond_to do |format|
      format.js
      format.html { render :index }
    end
  end

end
