class UsersController < Devise::RegistrationsController
  include RedirectionFiltersControllerHelper
  include CustomDevisePathsControllerHelper

  helper :all

  responders Responders::FlashResponder

  respond_to :html
  respond_to :js, only: [:hide_notice]

  prepend_before_filter :authenticate_scope!, only: [:edit, :update, :more_info, :hide_notice]
  before_filter :redirect_suspended_user

  skip_before_filter :verify_authenticity_token, only: [:hide_notice]
  skip_around_filter :destroy_if_previously_invited # Avoid DeviseInvitable shit

  # POST /signup
  def create
    build_resource
    @user = resource
    @user.referrer_site_token = cookies[:r]

    if UserManager.new(@user).create
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
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    successfully_updated = if needs_password?(resource, params)
      resource.update_with_password(params[resource_name])
    else
      # remove the virtual current_password attribute update_without_password
      # doesn't know how to ignore it
      params[resource_name].delete(:current_password)
      resource.update_without_password(params[resource_name])
    end

    if successfully_updated
      if is_navigational_format?
        flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ? :update_needs_confirmation : :updated
        set_flash_message :notice, flash_key
      end
      sign_in resource_name, resource, bypass: true
      Librato.increment 'users.events', source: 'update'
      respond_with resource, location: (params[:more_info_form] ? sites_url : after_update_path_for(resource))
    else
      clean_up_passwords resource
      respond_with resource
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

  private

  # check if we need password to update user data
  # ie if password or email was changed
  # extend this as needed
  def needs_password?(user, params)
    params[:user][:password].present?
  end

end
