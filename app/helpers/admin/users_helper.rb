module Admin::UsersHelper
  
  def admin_users_page_title(users)
    state = ""
    "#{users.total_entries} #{state} users".titleize
  end
  
  def display_bool(boolean)
    boolean ? "✓" : "-"
  end
  
  def display_date(date)
    date ? l(date, :format => :semi_full) : "-"
  end
  
end