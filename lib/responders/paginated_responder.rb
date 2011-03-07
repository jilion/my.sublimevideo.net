module Responders
  module PaginatedResponder

    def initialize(controller, resources, options={})
      super
      @per_page = options.delete(:per_page)
    end

    def to_html
      add_pagination_scope!
      super
    end

    def to_js
      add_pagination_scope!
      super
    end

    # Could be stubbed
    def self.per_page
      nil
    end

  private

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

    def page_params
      controller.request.params[:page]
    end

    def per_page(klass)
      PaginatedResponder.per_page || @per_page || (klass.respond_to?(:per_page) ? klass.per_page : 25)
    end

    def set_instance_variable(klass)
      controller.instance_variable_set("@#{controller.controller_name}", resource.page(page_params).per(per_page(klass)))
    end

  end
end
