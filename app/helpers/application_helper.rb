# coding: utf-8

module ApplicationHelper
  
  def display_bool(boolean)
    boolean ? "✓" : "-"
  end
  
  def display_date(date)
    date ? l(date, :format => :minutes_timezone) : "-"
  end
  
end