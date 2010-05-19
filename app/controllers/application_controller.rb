class ApplicationController < ActionController::Base
  protect_from_forgery
  responders Responders::FlashResponder, Responders::HttpCacheResponder, Responders::PaginatedResponder
  
  layout 'application'
  before_filter :beta_protection
  
  def paginated_scope(relation)
    Rails.logger.info controller_name
    instance_variable_set "@#{controller_name}", relation.paginate(:page => params[:page], :per_page => controller_name.classify.constantize.per_page)
  end
  hide_action :paginated_scope
  
protected
  
  def beta_protection
    if Rails.env.production? || Rails.env.staging?
      redirect_to beta_path unless session[:beta_key] == 'sublime33'
    end
  end
  
end