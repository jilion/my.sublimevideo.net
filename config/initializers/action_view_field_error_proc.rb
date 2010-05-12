ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  
  if instance.object.present?
    errors = instance.object.errors[instance.method_name.to_sym]
    if errors.length > 1
      last_error = " and #{errors.pop}"
      first_errors = errors.join(", ")
      inline_errors = first_errors + last_error
    else
      inline_errors = errors
    end
  end
  
  if html_tag =~ /<(input|textarea|select)/
    html_tag += "<div class='inline_errors'>This field #{inline_errors}</div>".html_safe
  end
  
  error_class = "errors"
  if html_tag =~ /<(input|textarea|select)[^>]+class=/
    class_attribute = html_tag =~ /class=['"]/
    html_tag.insert(class_attribute + 7, "#{error_class} ")
  elsif html_tag =~ /<(input|textarea|select)/
    first_whitespace = html_tag =~ /\s/
    html_tag[first_whitespace] = " class='#{error_class}' "
  end
  
  html_tag
end