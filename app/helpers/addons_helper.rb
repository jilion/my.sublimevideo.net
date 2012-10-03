module AddonsHelper

  def addon_choice_tag(site, addon, field_type)
    checked = site.addon_is_active?(addon) || (addon.price.zero? && !site.active_addon_in_category?(addon.category))

    _addon_choice_tag(name: "site_addons[#{addon.category}]", value: addon.name, checked: checked, field_type: field_type)
  end

  def offered_addon_choice_tag(field_type)
    _addon_choice_tag(checked: true, disabled: true, field_type: field_type)
  end

  def addon_price(addon)
    if addon.price.zero?
      'Free'
    elsif addon.beta?
      'Free (during beta)'
    else
      display_amount_with_sup(addon.price)
    end
  end

  def _addon_choice_tag(options = {})
    html = send("#{addon_input_type(options[:field_type])}_tag", options[:name] || '', options[:value] || '', options[:checked], disabled: options[:disabled] || false)
    html = hidden_field_tag(options[:name] || '', '0') + html if options[:field_type] == 'checkbox' && options[:name]

    html
  end

  private

  def addon_input_type(field_type)
    field_type == 'radio' ? 'radio_button' : 'check_box'
  end

end
