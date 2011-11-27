module DocsHelper

  def page_title(title)
    content_for :title, title
    content_tag :h2 do
      title
    end
  end

  def li_with_page_link(page, options = {}, &block)
    title = page.split('#').last
    title = title.split('/').last.gsub("-"," ").humanize if title == page
    content_tag :li, :class => (page == params[:page] ? "active" : nil) do
      link_to(options[:title] || title, "/#{page}") + (block_given? ? capture_haml { yield } : '')
    end
  end

end
