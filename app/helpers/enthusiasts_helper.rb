module EnthusiastsHelper
  
  def link_to_remove_fields(name, form)
    form.hidden_field(:_destroy) + link_to_function("<span>#{name}</span>".html_safe, "remove_fields(this)", :class => "remove")
  end
  
  def link_to_add_fields(name, form, association)
    new_object = form.object.class.reflect_on_association(association).klass.new
    fields = form.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function("<span>#{name}</span>".html_safe, "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")", :class => "add")
  end
  
end