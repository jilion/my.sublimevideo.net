module PlansHelper

  def plan_label_content(plan, site=nil, options={})
    discount = current_user.get_discount? && (site.plan.nil? || plan_change_discounted?(site.plan, plan))
    content_tag(:span, :class => "pricing") do
      price_box = content_tag(:strong, :class => "price") do
        display_amount_with_sup(plan.price) + (discount ? content_tag(:span, "", :class => "strike") : '')
      end

      price_box += content_tag(:span, :class => "details_label") do
        (plan.yearly? ? "per year" : "per month")
      end

      if discount
        price_box += content_tag(:strong, :class => "new_price") do
          display_amount_with_sup(plan.price(site))
        end
      end

      price_box += content_tag(:span, :class => "name") do
        plan.name.gsub(/\d/, '').titleize
      end

      if discount
        price_box += content_tag(:span, :class => "new_details_label") do
          raw(plan.yearly? ? "#{content_tag :strong, "first"} year" : "#{content_tag :strong, "first"} month")
        end
      end
      price_box
    end
  end

  def plan_change_discounted?(old_plan, new_plan)
    type = plan_change_type(old_plan, new_plan)
    type.nil? || !(type =~ /^delayed/)
  end

  def plan_change_type(old_plan, new_plan)
    if old_plan == new_plan
      nil
    elsif old_plan.beta_plan?
      "upgrade_from_beta"
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
    "#{"Standard " if plan.support == 'standard'}#{content_tag(:strong, "#{"Priority " if plan.support == 'priority'}")} Support".html_safe
  end

  def radio_button_options(site, plan, current_plan, options={})
    options = options
    options[:id]    ||= plan.dev_plan? ? "plan_dev" : "plan_#{plan.name}_#{plan.cycle}"
    options[:class] ||= "plan_radio"
    options["data-plan_title"] = plan.title(always_with_cycle: true)
    options["data-plan_price"] = display_amount(plan.price(site))
    if current_user.vat?
      options["data-plan_price_vat"] = display_amount(plan.price(site), vat: true)
    end
    unless site.new_record?
      options["data-plan_change_type"]  = plan_change_type(current_plan, plan)
      update_price = current_plan.upgrade?(plan) ? plan.price(plan_change_discounted?(site.plan, plan) ? site : nil) - current_plan.price(site) : plan.price(plan_change_discounted?(site.plan, plan) ? site : nil)
      options["data-plan_update_price"] = display_amount(update_price)
      if current_user.vat?
        options["data-plan_update_price_vat"] = display_amount(update_price, vat: true)
      end
      options["data-plan_update_date"]  = l((current_plan.upgrade?(plan) ? site.plan_cycle_started_at : site.plan_cycle_ended_at && site.plan_cycle_ended_at.tomorrow.midnight) || Time.now.utc.midnight, :format => :named_date)
    end
    options
  end

  def vat_price_info(klass)
    raw("Prices above exclude VAT, total amount charged will be #{content_tag(:strong, "?", class: klass)} (including #{display_vat_percentage} VAT).")
  end

end
