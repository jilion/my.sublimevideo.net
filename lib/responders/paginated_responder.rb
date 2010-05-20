module Responders
  module PaginatedResponder
    
    def to_html
      super unless add_pagination_scope!
    end
    
    def to_js
      super unless add_pagination_scope!
    end
    
  protected
    
    def add_pagination_scope!
      if get? && resource.is_a?(ActiveRecord::Relation) && controller.action_name == 'index'
        controller.instance_variable_set "@#{controller.controller_name}", resource.paginate(:page => controller.request.params[:page], :per_page => controller.controller_name.classify.constantize.per_page)
        true
      else
        false
      end
    end
  end
end