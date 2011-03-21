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
  
end
