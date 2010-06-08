module LimitAlertHelper
  
  def limit_amounts_select_options
    [["no notification", 0]] + User::LimitAlert.amounts_options.map do |amount|
      [number_to_currency(amount / 100, :precision => 0), amount]
    end
  end
  
end