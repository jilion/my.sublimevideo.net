module PaginateHelper
  
  def page_entries_info(collection)
    if collection.total_pages > 1
      (%{<b>%d&nbsp;-&nbsp;%d</b> of <b>%d</b> in total} % [collection.offset + 1, collection.offset + collection.length, collection.size]).html_safe
    end
  end
  
end