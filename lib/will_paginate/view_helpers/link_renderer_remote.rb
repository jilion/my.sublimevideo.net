module WillPaginate
  module ViewHelpers
    class LinkRendererRemote < LinkRenderer
    
    private
    
      def link(text, target, attributes = {})
        super(text, target, attributes.merge({ :'data-remote' => true }))
      end
      
    end
  end
end