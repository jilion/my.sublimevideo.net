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
  
  def footer
    "Copyright &copy; 2010 SublimeVideo&reg; | #{link_to "Terms & Conditions", page_path(:page => 'terms')} | #{link_to "Privacy Policy", page_path(:page => 'privacy') }".html_safe
  end
  
end