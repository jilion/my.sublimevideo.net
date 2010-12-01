module Responders
  module PaginatedResponder
    
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
      if get? && (resource.is_a?(ActiveRecord::Relation) || resource.is_a?(Mongoid::Criteria)) && controller.action_name == 'index'
        begin
          if controller.controller_name == 'delayed_jobs'
            set_instance_variable(Delayed::Job)
          else
            set_instance_variable(controller.controller_name.classify.constantize)
          end
        rescue
          set_instance_variable(resource[0].class) if resource.present?
        end
      end
    end
    
    def set_instance_variable(klass)
      controller.instance_variable_set "@#{controller.controller_name}", resource.paginate(:page => controller.request.params[:page] || 1, :per_page => klass.per_page)
    end
    
  end
end