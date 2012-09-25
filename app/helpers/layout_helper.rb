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
    { credit_card_warning: user,
      billing_address_incomplete: user
    }.inject({}) do |memo, (method, arg)|
      result = send(method, arg)
      memo[method] = result if result
      memo
    end
  end

end
