class UsersController < Devise::RegistrationsController
  include MyRedirectionFilters
  include CustomDevisePaths

  helper :all

  responders Responders::FlashResponder

  respond_to :html
  respond_to :js, only: [:hide_notice]

  prepend_before_filter :authenticate_scope!, only: [:edit, :update, :destroy, :more_info, :hide_notice]
  before_filter :redirect_suspended_user

  skip_before_filter :verify_authenticity_token, only: [:hide_notice]
  skip_around_filter :destroy_if_previously_invited # Avoid DeviseInvitable shit

  # POST /signup
  def create
    build_resource
    @user = resource
    @user.referrer_site_token = cookies[:r] if cookies[:r]

    if @user.save
      if @user.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, @user)
        respond_with resource, location: after_sign_up_path_for(@user)
      else
        set_flash_message :notice, :inactive_signed_up, reason: inactive_reason(@user) if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with @user, location: after_inactive_sign_up_path_for(@user)
      end
    else
      clean_up_passwords(@user)
      render :new
    end
  end

  # PUT /account
  def update
    @user = User.find(current_user.id)

    respond_with(@user) do |format|
      if @user.update_attributes(params[:user])
        set_flash_message :notice, :updated if is_navigational_format?
        format.html { redirect_to params[:more_info_form] ? sites_url(subdomain: 'my') : [:edit, :user] }
      else
        format.html { render :edit }
      end
    end
  end

  # /account
  def destroy
    @user = User.find(current_user.id)
    @user.attributes = params[:user] # set the current password

    respond_with(@user) do |format|
      if @user.archive
        format.html do
          sign_out(@user)
          set_flash_message :notice, :destroyed if is_navigational_format?
          redirect_to root_url(host: request.domain, protocol: 'http')
        end
      else
        format.html { render :edit }
      end
    end
  end

  # GET /account/more_info
  def more_info
    @user = User.find(current_user.id)

    render :more_info
  end

  # DELETE /notice/:id
  def hide_notice
    @user = User.find(current_user.id)
    unless @user.hidden_notice_ids.include?(params[:id].to_i)
      @user.hidden_notice_ids << params[:id].to_i
      @user.save
    end

    respond_to do |format|
      format.html { redirect_to [:sites] }
      format.js { render nothing: true }
    end
  end

end
