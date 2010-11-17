# coding: utf-8

module Admin::AdminHelper
  
  def display_bool(boolean)
    # boolean ? "✓" : "-"
    boolean ? "x" : "-"
  end
  
  def display_date(date)
    date ? l(date, :format => :semi_full) : "-"
  end
  
  def zeno?
    current_admin && current_admin.email == "zeno@jilion.com"
  end
  
end