module Transcoder
  module PandaStream
    VALID_ITEMS = %w[videos encodings profiles clouds]
    
    class << self
      
      def get(item_or_items_array, id=nil)
        assert_valid_items(item_or_items_array)
        
        if id.nil?
          Panda.get("/#{item_or_items_array.to_s.pluralize}.json").map(&:symbolize_keys!)
        else
          if item_or_items_array.is_a?(Array) && item_or_items_array.size > 1
            Panda.get("/#{item_or_items_array[0].to_s.pluralize}/#{id}/#{item_or_items_array[1].to_s.pluralize}.json").map(&:symbolize_keys!)
          else
            Panda.get("/#{item_or_items_array.to_s.pluralize}/#{id}.json").symbolize_keys!
          end
        end
      end
      
      def post(item, params={})
        assert_valid_items(item)
        
        Panda.post("/#{item.to_s.pluralize}.json", params).symbolize_keys!
      end
      
      def retry(item, id)
        raise "id can't be nil!" if id.nil?
        assert_valid_items(item, %w[encodings])
        
        Panda.post("/#{item.to_s.pluralize}/#{id}/retry.json").symbolize_keys!
      end
      
      
      def put(item, id, params={})
        assert_valid_items(item, %w[profiles])
        
        Panda.put("/#{item.to_s.pluralize}/#{id}.json", params).symbolize_keys!
      end
      
      def delete(item, id)
        assert_valid_items(item)
        
        Panda.delete("/#{item.to_s.pluralize}/#{id}.json").symbolize_keys!
      end
      
    private
      
      def assert_valid_items(item, valid_items=VALID_ITEMS)
        valid = case item
        when Array
          item.all? { |n| valid_items.include? n.to_s.pluralize }
        when String, Symbol
          valid_items.include? item.to_s.pluralize
        else
          false
        end
        raise "#{item.inspect} is not valid!" unless valid
      end
      
    end
    
  end
end