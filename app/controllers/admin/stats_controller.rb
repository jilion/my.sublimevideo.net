class Admin::StatsController < Admin::AdminController
  respond_to :html, :json

  def show
    render params[:page]
  end

end
