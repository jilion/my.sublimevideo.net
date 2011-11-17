module LayoutHelper

  def body_class
    params[:page] ? h(params[:page]) : nil
  end

  def title_env_prefix
    Rails.env.production? ? '' : "[#{Rails.env.upcase}] "
  end

  def title_subdomain_prefix(request)
    case request.subdomain
    when 'my'
      "MySublimeVideo"
    when 'docs'
      "SublimeVideo Documentation"
    else
      "SublimeVideo - HTML5 Video Player"
    end
  end

  def title_and_content_header(text, options = {})
    title(text)
    content_header(text, options)
  end

  def title(text)
    content_for :title do
      strip_tags(text)
    end
  end

  def content_header(text, options = {})
    options.reverse_merge!(header_size: 2)

    content_tag(:"h#{options.delete(:header_size)}", text.html_safe, options)
  end

  def activable_content_tag(tag, options = {})
    options.reverse_merge!(active_class: 'active')

    active = options[:urls].any? do |u|
      if u =~ /^http/
        controller.request.url =~ Regexp.new("^#{u}")
      else
        subdomain = options[:url_options].try(:[], :subdomain).present? ? "#{options[:url_options][:subdomain]}\." : ''
        page = case u.to_sym
               when :page
                 options[:url_options].try(:[], :page)
                when :root
                  ''
                else
                  u
                end
        Rails.logger.info "subdomain: #{subdomain}"
        Rails.logger.info "page: #{page}"
        controller.request.url =~ Regexp.new("^https?://#{subdomain}[^/]+#{(options[:namespace] || []).join('/')}/#{page}")
      end
    end
    classes = options[:class] ? options[:class].split(" ") : []
    classes << options[:active_class] if active

    tag_options = { class: classes.join(" ") }
    tag_options[:onclick] = options[:onclick]

    content_tag(tag, tag_options) { yield }
  end

  def activable_menu_item(tag, url, options = {})
    options.reverse_merge!(urls: [url], link_text: url.to_s.titleize)

    link = url.to_s

    activable_content_tag(tag, options) do
      block_given? ? link_to(link) { yield } : link_to(options[:link_text], link)
    end
  end

  def activable_menu_restful_item(tag, resources, options = {})
    options.reverse_merge!(urls: [resources], link_text: resources.to_s.titleize, link_options: {}, class: resources.to_s)
    options[:namespace] = Array.wrap(options[:namespace])

    namespace = options[:namespace].present? ? "#{options[:namespace].join('_')}_" : ''
    link = send("#{namespace}#{resources}_url", options[:url_options])

    activable_content_tag(tag, options) do
      block_given? ? link_to(link, options[:link_options]) { yield } : link_to(options[:link_text], link, options[:link_options])
    end
  end

end
