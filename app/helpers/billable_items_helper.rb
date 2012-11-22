# coding: utf-8
module BillableItemsHelper

  def highlighted_class(addon_plan)
    return nil unless params[:h]

    param_addon = params[:h].split('-')

    highlited_class = param_addon[0] == addon_plan.addon.name && param_addon[1] == addon_plan.name ? 'highlight' : nil
  end

  def beta_loader_required_notice(addon_plan)
    if addon_plan.required_stage == 'beta'
      content_tag(:small) do
        "(requires #{link_to 'beta loader', '', class: 'loader_code hl', data: { token: @site.token }})".html_safe
      end
    end
  end

  def billable_item_price(billable_item)
    if billable_item.price.zero?
      'free'
    elsif billable_item.beta?
      "<em>free during beta</em> #{content_tag(:s, display_amount_with_sup(billable_item.price))}".html_safe
    else
      display_amount_with_sup(billable_item.price)
    end
  end

  def trial_days_remaining(site, billable_item)
    trial_days_remaining_for_billable_item = site.trial_days_remaining_for_billable_item(billable_item)
    case trial_days_remaining_for_billable_item
    when 0
      'trial ended'
    when 1
      'last day of trial'
    else
      "free trial – #{pluralize(trial_days_remaining_for_billable_item || 30, 'day')} remaining" unless billable_item.free?
    end
  end

end
