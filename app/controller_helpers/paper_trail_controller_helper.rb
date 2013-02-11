module PaperTrailControllerHelper

  private

  def user_for_paper_trail
    params[:user][:email].downcase! if params[:user] && params[:user][:email]
    current_user rescue nil
  end

  def info_for_paper_trail
    { admin_id: current_admin_id, ip: current_ip }
  end

  def current_admin_id
    current_admin.try(:id) rescue nil
  end

  def current_ip
    request.remote_ip rescue nil
  end

end
