class PrivateApi::UsersController < SublimeVideoPrivateApiController
  before_filter :_find_user_by_id!, only: [:show]

  # GET /private_api/users/:id
  def show
    expires_in 2.minutes
    respond_with(@user) if stale?(@user)
  end

  private

  def _find_user_by_id!
    @user = User.with_state('active').find_by_id!(params[:id])
  rescue ActiveRecord::RecordNotFound
    body = { error: "User with id #{params[:id]} could not be found." }
    render request.format.ref => body, status: 404
  end
end
