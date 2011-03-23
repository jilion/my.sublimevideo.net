module PlansHelper

  def plan_label_content(plan, options={})
    pricing_div = content_tag(:div, :class => "pricing") do
      content_tag(:h4, :class => "price") do
        display_amount_with_sup(plan.price)
      end + content_tag(:span, :class => "name") do
        plan.name.titleize
      end + (options[:year] ? "per year" : "per month")
    end
  end

  def plan_change_type(old_plan, new_plan)
    if old_plan == new_plan
      nil
    elsif new_plan.dev_plan?
      "delayed_downgrade_to_dev"
    elsif old_plan.dev_plan?
      "upgrade_from_dev"
    elsif old_plan.yearly? && new_plan.monthly?
      if old_plan.month_price(10) < new_plan.month_price(10)
        "delayed_upgrade"
      elsif old_plan.month_price(10) == new_plan.month_price(10)
        "delayed_change"
      else
        "delayed_downgrade"
      end
    elsif old_plan.month_price(10) <= new_plan.month_price(10)
      "upgrade"
    else
      "delayed_downgrade"
    end
  end
  
  def plan_support(plan)
    "#{"Standard " if plan.support == 'standard'}#{content_tag(:strong, "#{"Priority " if plan.support == 'priority'} Support")}".html_safe
  end

  def radio_button_options(site, plan, current_plan, options={})
    options = options
    options[:id]    = plan.dev_plan? ? "plan_dev" : "plan_#{plan.name}_#{plan.cycle}"
    options[:class] = "plan_radio"
    options["data-plan_title"] = plan.title(always_with_cycle: true)
    options["data-plan_price"] = display_amount(plan.price)
    unless site.new_record?
      options["data-plan_change_type"]  = plan_change_type(current_plan, plan)
      options["data-plan_update_price"] = display_amount(current_plan.upgrade?(plan) ? plan.price - current_plan.price : plan.price)
      options["data-plan_update_date"]  = l((current_plan.upgrade?(plan) ? site.plan_cycle_started_at : site.plan_cycle_ended_at && site.plan_cycle_ended_at.tomorrow.midnight) || Time.now.utc.midnight, :format => :named_date)
    end
    options
  end

end
