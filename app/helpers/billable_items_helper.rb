# coding: utf-8
module BillableItemsHelper

  def addon_plan_choice_tag(site, addon_plan, field_type)
    checked = site.addon_plan_is_active?(addon_plan) || (addon_plan.price.zero? && !site.active_addon_in_category?(addon_plan.addon.name))

    _addon_choice_tag(name: "site_addons[#{addon_plan.addon.name}]", value: addon_plan.name, checked: checked, field_type: field_type)
  end

  def offered_addon_choice_tag(field_type)
    _addon_choice_tag(checked: true, disabled: true, field_type: field_type)
  end

  def billable_item_price(billable_item)
    if billable_item.price.zero?
      'free'
    elsif billable_item.beta?
      'free (during beta)'
    else
      display_amount_with_sup(billable_item.price)
    end
  end

  def trial_days_remaining(site, billable_item)
    trial_days_remaining_for_billable_item = site.trial_days_remaining_for_billable_item(billable_item)
    case trial_days_remaining_for_billable_item
    when 0
    when 1
      'last days of trial'
    else
      "free trial – #{pluralize(trial_days_remaining_for_billable_item || 30, 'day')} remaining"
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
