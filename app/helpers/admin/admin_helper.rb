module Admin::AdminHelper
  
  def display_bool(boolean)
    boolean ? "✓" : "-"
  end
  
  def display_date(date)
    date ? l(date, :format => :semi_full) : "-"
  end
  
end