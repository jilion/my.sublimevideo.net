module LayoutHelper

  def title_and_content_header(text, options={})
    title(text)
    content_header(text, options)
  end

  def title(text)
    content_for :title do
      strip_tags(text)
    end
  end

  def content_header(text, options={})
    options.reverse_merge!(:header_size => 2)

    content_tag(:"h#{options.delete(:header_size)}", text.html_safe, options)
  end

  def activable_content_tag(tag, options={})
    options.reverse_merge!(:active_class => 'active')

    active = options[:urls].any? do |u|
      controller.request.url =~ Regexp.new("^https?://[^/]+#{options[:namespace].join('/') + '/' if options[:namespace]}#{u}")
    end
    classes = options[:class] ? options[:class].split(" ") : []
    classes << options[:active_class] if active
    
    tag_options = { :class => classes.join(" ") }
    tag_options[:onclick] = options[:onclick]
    
    content_tag(tag, tag_options) do
      yield
    end
  end

  def activable_menu_item(tag, resources, options={})
    options.reverse_merge!(:namespace => [], :urls => [resources], :link_text => resources.to_s.titleize, :class => resources.to_s)
    options[:namespace] = [options[:namespace]] unless options[:namespace].is_a?(Array)
    link = send("#{options[:namespace].join('_')}#{'_' if options[:namespace].present?}#{resources}_path", options[:resource])

    activable_content_tag(tag, options) do
      if block_given?
        link_to(link) do
          yield
        end
      else
        link_to(options[:link_text], link)
      end
    end
  end

end
