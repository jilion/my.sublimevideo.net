# Transcoder is a proxy class that give a simple API to transcoding service methods
# Currently, only PandaStream implements the Transcoder API
module Transcoder
  require 'transcoder/panda_stream'
  
  @@transcoding_service = Transcoder::PandaStream
  
  class << self
    
    def transcoding_service=(transcoding_service)
      @@transcoding_service ||= transcoding_service
    end
    
    # Get (return information):
    # - all items: +item_or_items_array+ is an item name (:video for example), +id+ is nil
    # - a single item: give an +item_or_items_array+ is an item name (:video for example), +id+ is not nil
    # - nested items: +item_or_items_array+ is an array of item names like [:video, :encodings], +id+ is ignored
    def get(item_or_items_array, id=nil)
      transcoding_service.get(item_or_items_array, id)
    end
    
    # Post (create) a single item: give an +item+ name (:video for example) and a hash of +params+
    def post(item, params={})
      transcoding_service.post(item, params)
    end
    
    # Put (update) a single item: give an +item+ name (:video for example), an +id+ and a hash of +params+
    # +id+ can't be nil
    def put(item, id, hash={})
      raise "id can't be nil!" if id.nil?
      transcoding_service.put(item, id, hash)
    end
    
    # Delete a single item: give an item name (:video for example) and an +id+
    # +id+ can't be nil
    def delete(item, id)
      raise "id can't be nil!" if id.nil?
      transcoding_service.delete(item, id)
    end
    
    def method_missing(item, *args)
      transcoding_service.send(item, *args)
    end
    
  private
    
    def transcoding_service
      @@transcoding_service
    end
    
  end
  
end