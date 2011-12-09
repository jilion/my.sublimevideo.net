class Admin::StatsController < AdminController
  respond_to :html, :json

  def index
  end

  def show
    render params[:id]
  end

  def users
    respond_to do |format|
      format.json { render json: UsersStat.json(params[:start], params[:end]) }
    end
  end

end
