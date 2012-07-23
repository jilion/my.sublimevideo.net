module Responders
  module PaginatedResponder

    def initialize(controller, resources, options = {})
      super
      @options = options
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
      return unless activate_paginate?

      if controller.controller_name == 'delayed_jobs'
        set_instance_variable(Delayed::Job)
      else
        set_instance_variable
      end
    end

    def activate_paginate?
      get? &&
      (resource.is_a?(ActiveRecord::Relation) || resource.is_a?(Mongoid::Criteria)) &&
      (controller.action_name == 'index' || @options[:paginate])
    end

    def klass
      @klass ||= begin
        controller.controller_name.classify.constantize
      rescue
        resource.present? ? resource[0].class : nil
      end
    end

    def page_params
      controller.request.params[:page]
    end

    def per_page(qlass = klass)
      PaginatedResponder.per_page || @options[:per_page] || klass.try(:per_page) || 25
    end

    def set_instance_variable(qlass = klass)
      controller.instance_variable_set("@#{controller.controller_name}", resource.page(page_params).per(per_page(qlass)))
    end

  end
end
