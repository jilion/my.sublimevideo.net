module PaginateHelper

  def remote_will_paginate(collection = nil, options = {})
    will_paginate(collection, options.merge(:renderer => 'WillPaginate::ViewHelpers::LinkRendererRemote'))
  end

  def page_entries_info(collection)
    if collection.total_pages > 1
      (%{<div class="page_info"><strong>%d&nbsp;-&nbsp;%d</strong> of <strong>%d</strong></div>} % [collection.offset + 1, collection.offset + collection.length, collection.total_entries]).html_safe
    end
  end

end
