# coding: utf-8
module ApplicationHelper

  def display_bool(boolean)
    boolean ? "✓" : "-"
  end

  def display_date(date)
    date ? l(date, :format => :minutes_timezone) : "-"
  end

  def display_percentage(fraction)
    number_to_percentage(fraction * 100.0, :precision => 2)
  end

  def display_amount(amount_in_cents)
    number_to_currency(amount_in_cents / 100.0)
  end

end
