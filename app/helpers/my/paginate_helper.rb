module My::PaginateHelper

  def page_entries_info(collection)
    if collection.num_pages > 1
      (%{<div class="page_info"><strong>%d&nbsp;-&nbsp;%d</strong> of <strong>%d</strong></div>} % [collection.ast.offset.expr + 1, collection.ast.offset.expr + collection.length, collection.total_count]).html_safe
    end
  end

end
