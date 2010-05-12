class CustomFormBuilder < ActionView::Helpers::FormBuilder
  
  def label(method, text = nil, options = {})
    if options[:require]
      text += "<abbr title='required'>*</abbr>".html_safe
    end
    if options[:notice]
      text += " <em>#{options[:notice]}</em>".html_safe
    end
    super
  end
  
end