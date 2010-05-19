module Responders
  module PaginatedResponder
    def to_html
      if get? && resource.is_a?(ActiveRecord::Relation) && controller.action_name == 'index'
        controller.paginated_scope(resource)
      end
      super
    end
  end
end