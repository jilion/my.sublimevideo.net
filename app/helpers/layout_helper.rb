module LayoutHelper

  def title_and_content_header(text, options = {})
    title(text)
    content_header(text, options)
  end

  def title(text, options = {})
    @page_title_prefix = options[:prefix] if options[:prefix]
    @page_title = strip_tags(text)
  end

  def content_header(text, options = {})
    options.reverse_merge!(header_size: 2)

    content_tag(:"h#{options.delete(:header_size)}", text.html_safe, options)
  end

  def sticky_notices(user, sites)
    {}
  end

  def svg(width, height, options = {}, &block)
    content_tag(:svg, options.reverse_merge(version: '1.1', xmlns: 'http://www.w3.org/2000/svg', width: width, height: height)) do
      capture_haml(&block) if block_given?
    end
  end

end
