module LayoutHelper

  def title_and_content_header(text, options = {})
    title(text)
    content_header(text, options)
  end

  def title(text)
    @page_title = strip_tags(text)
  end

  def content_header(text, options = {})
    options.reverse_merge!(header_size: 2)

    content_tag(:"h#{options.delete(:header_size)}", text.html_safe, options)
  end

end
