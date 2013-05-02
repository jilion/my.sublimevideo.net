class BillingsController < ApplicationController

  before_filter :_find_user, only: [:edit, :update]

  # GET /account/billing/edit
  def edit
    _store_return_to
  end

  # PUT /account/billing
  def update
    @user.assign_attributes(params[:user].merge(remote_ip: request.try(:remote_ip)))

    respond_with(@user, flash: false) do |format|
      format.html { @user.save ? success_response : render(:edit) }
    end
  end

  private

  def _find_user
    @user = User.find(current_user.id)
  end

  def _store_return_to
    session[:return_to] = params.delete(:return_to) if params[:return_to]
  end

  def success_response
    if @user.d3d_html # 3-d secure identification needed
      render text: _d3d_html_inject
    else
      redirect_to _redirect_route, _notice_and_alert
    end
  end

  def _d3d_html_inject
    "<!DOCTYPE html><html><head><title>3DS Redirection</title></head><body>#{@user.d3d_html}</body></html>"
  end

  def _notice_and_alert
    @user.i18n_notice_and_alert || { notice: t('flash.billings.update.notice') }
  end

  def _redirect_route
    session[:return_to] ? session.delete(:return_to) : [:edit, :user]
  end

end
