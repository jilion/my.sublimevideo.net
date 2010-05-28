module WillPaginate
  module ViewHelpers
    class LinkRendererRemote < LinkRenderer
    
    protected
      
      def page_number(page)
        unless page == current_page
          link(page, page, :rel => rel_value(page), :class => "page_link")
        else
          tag(:em, page, :class => "current_page")
        end
      end
      
    private
      
      def link(text, target, attributes = {})
        super(text, target, attributes.merge({ :'data-remote' => true, :onclick => "MySublimeVideo.showTableSpinner()" }))
      end
      
    end
  end
end