module My::PlansHelper

  def plan_label_content(plan, site=nil, options={})
    content_tag(:span, class: "pricing") do
      price_box = content_tag(:strong, class: "price") do
        display_amount_with_sup(plan.price)
      end

      price_box += content_tag(:span, class: "details_label") do
        (plan.yearly? ? "per site/year" : "per site/month")
      end

      price_box += content_tag(:span, class: "name") do
        plan.name.gsub(/\d/, '').titleize
      end

      price_box
    end
  end

  def plan_change_type(site, old_plan, new_plan)
    if old_plan == new_plan
      site.in_trial? ? "skipping_trial" : nil
    elsif site.trial_not_started_or_in_trial?
      new_plan.free_plan? ? "in_trial_downgrade_to_free" : "in_trial_update"
    elsif new_plan.free_plan?
      "delayed_downgrade_to_free"
    elsif old_plan.free_plan?
      "upgrade_from_free"
    elsif old_plan.yearly? && new_plan.monthly?
      if old_plan.month_price(10) < new_plan.month_price(10)
        "delayed_upgrade"
      elsif old_plan.month_price(10) == new_plan.month_price(10)
        "delayed_change"
      else
        "delayed_downgrade"
      end
    elsif old_plan.upgrade?(new_plan)
      "upgrade"
    else
      "delayed_downgrade"
    end
  end

  def plan_plays(plan)
    text = case plan.video_views
           when 0
             "Unlimited"
           else
             number_with_delimiter(plan.video_views)
           end

    "#{text} Plays".html_safe
  end

  def plan_support(plan)
    text = case plan.support
           when 'vip_email'
             "VIP Email"
           else
             plan.support.titleize
           end

    "#{text} Support".html_safe
  end

  def plan_stats_retention_days(plan)
    text = case plan.stats_retention_days
           when nil
             "Unlimited"
           when 0
             "24h"
           else
             "#{plan.stats_retention_days}d"
           end

    "#{content_tag :span, text} Data Retention".html_safe
  end

  def radio_button_options(site, current_plan, new_plan, options={})
    options = options
    options[:id]    ||= new_plan.free_plan? ? "plan_free" : "plan_#{new_plan.name}_#{new_plan.cycle}"
    options[:class] ||= "plan_radio"
    options["data-plan_title"] = new_plan.title(always_with_cycle: true)
    options["data-plan_price"] = display_amount(new_plan.price)
    if current_user.vat?
      options["data-vat"] = display_vat_percentage
      options["data-plan_price_vat"] = display_amount(new_plan.price, vat: true)
    end

    if site.persisted?
      options["data-plan_change_type"] = plan_change_type(site, current_plan, new_plan)
      update_price = current_plan.upgrade?(new_plan) ? new_plan.price - site.last_paid_plan_price : new_plan.price

      options["data-plan_update_price"] = display_amount(update_price)

      options["data-plan_update_price_vat"] = display_amount(update_price, vat: true) if current_user.vat?

      options["data-plan_update_date"] = l(if site.trial_not_started_or_in_trial?
        (site.trial_end || BusinessModel.days_for_trial.days.from_now).tomorrow
      elsif current_plan.upgrade?(new_plan)
        site.plan_cycle_started_at || Time.now.utc.midnight
      else
        (site.plan_cycle_ended_at && site.plan_cycle_ended_at.tomorrow.midnight) || Time.now.utc.midnight
      end, format: :named_date)
    end

    options
  end

  def vat_price_info(klass)
    raw "Prices above exclude VAT, the total amount charged will be #{content_tag(:span, "?", class: klass)}."
  end

  def credit_card_state(user)
    if !user.cc? || !user.billing_address_complete?
      'none'
    elsif user.cc_expired?
      'expired'
    else
      'present'
    end
  end

end
