module AddonsHelper

  def addon_choice_tag(site, addon, addons_count)
    checked = site.addon_is_active?(addon) || (addon.price.zero? && !site.active_addon_in_category?(addon.category))
    input_type = addons_count == 1 ? 'check_box' : 'radio_button'

    html = send("#{input_type}_tag", "site_addons[#{addon.category}]", addon.name, checked)
    html = hidden_field_tag("site_addons[#{addon.category}]", '0') + html if addons_count == 1

    html
  end

  def addon_price(addon)
    addon.price.zero? ? 'Free' : display_amount_with_sup(addon.price)
  end

end
