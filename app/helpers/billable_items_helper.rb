# coding: utf-8
module BillableItemsHelper

  def highlighted_class(billable_item)
    return nil unless params[:h]

    param_billable_item = params[:h].split('-')

    highlited_class = if billable_item.is_a?(App::Design)
      param_billable_item[0] == billable_item.name ? 'highlight' : nil
    elsif param_billable_item.size == 2
      param_billable_item[0] == billable_item.addon.name && param_billable_item[1] == billable_item.name ? 'highlight' : nil
    end
  end

  def design_label_content(design)
    raw t("app_designs.#{design.name}") + beta_loader_required_notice(design).to_s
  end

  def addon_label_content(addon_plan)
    raw t("addon_plans.#{addon_plan.addon.name}.#{addon_plan.name}") + beta_loader_required_notice(addon_plan).to_s
  end

  def beta_loader_required_notice(addon_plan)
    if addon_plan.required_stage == 'beta'
      content_tag(:small) do
        " (requires #{link_to 'beta loader', '', class: 'loader_code hl', data: { token: @site.token }})".html_safe
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
      if !(billable_item.beta? || billable_item.free?)
        "free trial – #{pluralize(trial_days_remaining_for_billable_item || 30, 'day')} remaining"
      end
    end
  end

end
