# coding: utf-8
class KitExhibit < DisplayCase::Exhibit

  def self.applicable_to?(object, context)
    object.class.name == 'Kit'
  end

  def render_name_as_link(view_template, site)
    view_template.link_to view_template.edit_site_kit_path(site, self), class: 'name' do
      label(view_template)
    end
  end

  def label(view_template)
    view_template.content_tag(:span, "#{self.name}") + " #{view_template.content_tag(:strong, "id: #{self.identifier}")}".html_safe
  end

  def eql?(other)
    (self.class == other.class) && (self.to_model == other.to_model)
  end
  alias :== eql?

end
