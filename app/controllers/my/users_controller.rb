class My::UsersController < Devise::RegistrationsController
  include MyRedirectionFilters

  responders Responders::FlashResponder

  respond_to :html
  respond_to :js, only: [:hide_notice]

  before_filter :redirect_suspended_user

  # POST /signup
  def create
    build_resource
    @user = resource
    @user.referrer_site_token = cookies[:r] if cookies[:r]

    if @user.save
      if @user.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, @user)
        respond_with resource, location: sites_url(subdomain: 'my')
      else
        set_flash_message :notice, :inactive_signed_up, reason: inactive_reason(@user) if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with @user, location: after_inactive_sign_up_path_for(@user)
      end
    else
      clean_up_passwords(@user)
      params[:page] = 'home'
      render 'www/pages/home'
    end
  end

  # PUT /account
  def update
    @user = User.find(current_user.id)

    respond_with(@user) do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to [:edit, :user] }
      else
        format.html { render :edit }
      end
    end
  end

  # /account
  def destroy
    @user = User.find(current_user.id)
    @user.current_password = params[:user] && params[:user][:current_password]

    respond_with(@user) do |format|
      if @user.archive
        format.html do
          sign_out(@user)
          redirect_to root_url(subdomain: 'www'), notice: I18n.t("devise.registrations.destroyed")
        end
      else
        format.html { render :edit }
      end
    end
  end

  def after_update_path_for(resource_or_scope)
    [:edit, :"#{Devise::Mapping.find_scope!(resource_or_scope)}"]
  end

  # PUT /hide_notice/:id
  def hide_notice
    @user = User.find(current_user.id)
    @user.hidden_notice_ids << params[:id].to_i
    @user.save

    respond_to do |format|
      format.html { redirect_to [:sites] }
      format.js { render nothing: true }
    end
  end

end
