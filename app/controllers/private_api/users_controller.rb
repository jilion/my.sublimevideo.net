class PrivateApi::UsersController < SublimeVideoPrivateApiController
  before_filter :_find_user_by_id!, only: [:show]

  # GET /private_api/users/:id
  def show
    expires_in 2.minutes, public: true
    respond_with(@user) if stale?(@user)
  end

  private

  def _find_user_by_id!
    @user = User.with_state('active').find_by_id!(params[:id])
  end
end
