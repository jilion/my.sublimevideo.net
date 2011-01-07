module LayoutHelper

  def title_and_content_header(text, header_size = 2)
    title(text)
    content_header(text, header_size)
  end

  def title(text)
    content_for :title do
      strip_tags(text)
    end
  end

  def content_header(text, header_size = 2)
    content_tag(:"h#{header_size}", text.html_safe)
  end

  def activable_content_tag(tag, options = {})
    options.reverse_merge!(:active_class => 'active')

    classes = options[:class] ? options[:class].split(" ") : []
    classes << options[:active_class] if options[:urls].any? { |u| controller.request.url.include?("#{options[:namespace].join('/') + '/' if options[:namespace]}#{u}") }
    content_tag(tag, :class => classes.join(" ")) do
      yield
    end
  end

  def activable_menu_item(tag, resources, options = {})
    options.reverse_merge!(:namespace => [], :urls => [resources], :link_text => resources.to_s.titleize, :class => resources.to_s)
    options[:namespace] = [options[:namespace]] unless options[:namespace].is_a?(Array)
    link = send("#{options[:namespace].join('_')}#{'_' if options[:namespace].present?}#{resources}_path")

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
