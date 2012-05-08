ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|

  error_class = "errors"
  if html_tag =~ /<(input|textarea|select)[^>]+class=/
    class_attribute = html_tag =~ /class=['"]/
    html_tag.insert(class_attribute + 7, "#{error_class} ")
  elsif html_tag =~ /<(input|textarea|select)/
    first_whitespace = html_tag =~ /\s/
    html_tag[first_whitespace] = " class='#{error_class}' "
  end

  if instance.object.present? && html_tag =~ /<(input|textarea|select)/
    if errors = instance.object.errors.messages.delete(instance.method_name.to_sym)
      if errors.length > 1
        last_error = " and #{errors.pop}"
        first_errors = errors.join(", ")
        inline_errors = first_errors + last_error
      else
        inline_errors = errors.pop
      end
      attribute_name = instance.object.class.human_attribute_name(instance.method_name.to_sym)
      if html_tag =~ /<(input|textarea|select)[^>]+type="(radio|checkbox)"/
        html_tag = "<div class='inline_errors'><span>#{attribute_name} #{inline_errors}</span></div>".html_safe + html_tag
      else
        html_tag += "<div class='inline_errors'><span>#{attribute_name} #{inline_errors}</span></div>".html_safe
      end
    end
  end

  html_tag
end
