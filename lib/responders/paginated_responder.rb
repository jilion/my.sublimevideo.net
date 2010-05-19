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
      controller.paginated_scope(resource) if get? && resource.is_a?(ActiveRecord::Relation)
    end
  end
end