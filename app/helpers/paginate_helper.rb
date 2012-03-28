module PaginateHelper

  def page_entries_info(collection)
    if collection.num_pages > 1
      if collection.class == ActiveRecord::Relation
        (%{<div class="page_info"><strong>%d&nbsp;-&nbsp;%d</strong> of <strong>%d</strong></div>} % [collection.ast.offset.expr + 1, collection.ast.offset.expr + collection.length, collection.total_count]).html_safe
      else
        (%{<div class="page_info"><strong>%d&nbsp;-&nbsp;%d</strong> of <strong>%d</strong></div>} % [collection.offset + 1, collection.offset + collection.entries.size, collection.total_count]).html_safe
      end
    end
  end

end
