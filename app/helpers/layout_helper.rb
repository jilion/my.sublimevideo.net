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
    content_for :content_header do
      content_tag(:"h#{header_size}", text.html_safe)
    end
  end
  
  def activable_content_tag(tag, controller, options = {})
    options.reverse_merge!(:active_class => 'active', :class => controller.to_s)
    
    classes = options[:class] ? options[:class].split(" ") : []
    classes << options[:active_class] if controller.to_s == controller_name.to_s
    
    content_tag(tag, :class => classes.join(" ")) do
      yield
    end
  end
  
  def activatable_menu_item(tag, resources, options = {})
    options.reverse_merge!(:namespace => [], :controller_name => resources.to_s, :link_text => resources.to_s.titleize, :class => resources.to_s)
    options[:namespace] = Array(options[:namespace]) unless options[:namespace].is_a?(Array)
    link = send("#{options[:namespace].join('_')}#{'_' if options[:namespace].present?}#{resources}_path")
    
    activable_content_tag(tag, options[:controller_name], options) do
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