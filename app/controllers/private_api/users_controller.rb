class PrivateApi::UsersController < SublimeVideoPrivateApiController
  include ApisControllerHelper

  before_filter :_set_user, only: [:show]

  # GET /private_api/users/:id
  def show
    _with_cache_control { respond_with(@user) if stale?(@user) }
  end

  private

  def _set_user
    @user = User.with_state('active').find(params[:id])
  end
end
