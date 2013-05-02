# coding: utf-8
module BillableItemsHelper

  def design_label_content(design)
    raw t("app_designs.#{design.name}") + beta_loader_required_notice(design).to_s
  end

  def addon_label_content(addon_plan)
    raw t("addon_plans.#{addon_plan.addon.name}.#{addon_plan.name}") + beta_loader_required_notice(addon_plan).to_s
  end

  def addon_plan_is_selected?(site, addon_plan)
    (action_name == 'show' && params[:p] == addon_plan.name) || site.addon_plans.include?(addon_plan)
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
      "#{content_tag(:em, 'free during beta')} #{content_tag(:s, display_amount_with_sup(billable_item.price))}".html_safe
    else
      display_amount_with_sup(billable_item.price)
    end
  end

  def trial_days_remaining_text(trial_days_remaining, billable_item)
    case trial_days_remaining
    when 0
      t = 'Trial ended.'
      if !current_user.cc? || current_user.cc_expired?
        t << " Please #{link_to('provide a valid credit card', edit_billing_url(return_to: url_for), class: 'hl')}."
      end
      raw t
    when 1
      'Last day of trial.'
    else
      if !billable_item.beta? && !billable_item.free?
        "Free trial – #{pluralize(trial_days_remaining || BusinessModel.days_for_trial, 'day')} remaining."
      end
    end
  end

end
