# class ApplicationResponder < ActionController::Responder
#   include Responders::FlashResponder
#   include Responders::HttpCacheResponder
#   include Responders::PaginatedResponder
# end
# 
# ApplicationController.respond_to :html
# ApplicationController.responder = ApplicationResponder
