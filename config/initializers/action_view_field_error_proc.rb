ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  error_class = 'errors'
  if instance.object.present? && html_tag =~ /<(input|textarea|select)/
    if p = html_tag =~ /( class=['"])/
      html_tag.insert(p + $1.size, "#{error_class} ")
    else
      p = html_tag =~ /(\s+)/
      html_tag.insert(p + $1.size, " class='#{error_class}' ")
    end

    method_name = instance.instance_variable_get(:@method_name).to_sym

    if errors = instance.object.errors.messages.delete(method_name)
      if errors.length > 1
        last_error = " and #{errors.pop}"
        first_errors = errors.join(', ')
        inline_errors = first_errors + last_error
      else
        inline_errors = errors.pop
      end

      attribute_name = instance.object.class.human_attribute_name(method_name)
      inline_errors = inline_errors =~ /#{attribute_name}/ ? inline_errors : "#{attribute_name} #{inline_errors}"

      if html_tag =~ /(radio|checkbox)/
        html_tag = "<div class='inline_errors'><span>#{inline_errors}</span></div>".html_safe + html_tag
      else
        html_tag += "<div class='inline_errors'><span>#{inline_errors}</span></div>".html_safe
      end
    end
  end

  html_tag
end
