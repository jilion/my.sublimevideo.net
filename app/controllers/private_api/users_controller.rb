class PrivateApi::UsersController < SublimeVideoPrivateApiController
  before_filter :_set_user, only: [:show]

  # GET /private_api/users/:id
  def show
    expires_in 2.minutes, public: true
    respond_with(@user) if stale?(@user)
  end

  private

  def _set_user
    @user = User.with_state('active').find(params[:id])
  end
end
