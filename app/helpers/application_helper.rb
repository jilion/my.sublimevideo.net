# coding: utf-8
module ApplicationHelper

  def display_bool(boolean)
    boolean == 0 || boolean.blank? || !boolean ? "-" : "✓"
  end

  def display_date(date)
    date ? l(date, :format => :minutes_timezone) : "-"
  end

  def display_percentage(fraction)
    number_to_percentage(fraction * 100.0, :precision => 2, :strip_insignificant_zeros => true)
  end
  
  def display_vat_percentage
    number_to_percentage(Vat.for_country(current_user.country) * 100, :precision => 0, :strip_insignificant_zeros => true)
  end

  def display_amount(amount_in_cents, options={})
    if options[:vat] && current_user.vat?
      vat_rate        = Vat.for_country(current_user.country)
      amount_in_cents = (amount_in_cents * (1.0 + vat_rate)).round
    end
    number = amount_in_cents / 100.0
    number_to_currency(number, :precision => (!options[:decimals] && number == number.to_i ? 0 : options[:decimals] || 2))
  end

  def display_amount_with_sup(amount_in_cents)
    units    = amount_in_cents / 100
    decimals = amount_in_cents - (units * 100)
    "#{number_to_currency(units, :precision => 0)}#{content_tag(:sup, ".#{decimals}") unless decimals.zero?}".html_safe
  end

  def info_box(options={}, &block)
    content_tag(:div, :class => "info_box" + (options[:class] ? " #{options[:class]}" : "")) do
      capture_haml(&block).chomp + content_tag(:span, nil, :class => "arrow")
    end
  end

end
