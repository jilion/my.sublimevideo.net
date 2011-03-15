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

end
