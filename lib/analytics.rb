# TODO: Refactor and extract all this (already on the way)
module Analytics
  class Engine
    
    attr_reader :report
    
    # Create a report
    #
    # report_name - 'top_five_posters', 'comments_per_day'...
    # options     - A Hash of options for the report, see subclasses for a list
    #               of possible options
    #
    # Returns a Analytics::resources.classify::Report instance
    def self.report(report_name, options)
      "Analytics::#{report_name.to_s.classify}".constantize.new(options)
    end
  end
  
  class Report
    include Grafico::Helpers
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::JavaScriptHelper
    
    attr_reader :render_engine, :graph_type
    
    def initialize(resources, report_name, options)
    end
    
    def date_can_be_changed?
      false
    end
  end
end