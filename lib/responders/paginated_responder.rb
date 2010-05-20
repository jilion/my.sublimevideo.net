module Responders
  module PaginatedResponder
    def initialize(controller, resources, options={})
      super
    end
    
    def to_html
      add_pagination_scope!
      super
    end
    
    def to_js
      add_pagination_scope!
      super
    end
    
  protected
    
    def add_pagination_scope!
      if get? && resource.is_a?(ActiveRecord::Relation) && controller.action_name == 'index'
       controller.instance_variable_set "@#{controller.controller_name}", resource.paginate(:page => controller.request.params[:page], :per_page => controller.controller_name.classify.constantize.per_page)
      end
    end
  end
end