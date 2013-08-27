include ActionView::Helpers::NumberHelper

namespace :balances do
  desc "Print balances history from 12.31.2012 from end of last month"
  task history: :environment do
    user_balances = User.active.with_balance.inject(Hash.new(0)) do |hash, user|
      hash[user.id] = user.balance
      hash
    end

    print "date, users_total, balances_total\n"
    date = Time.now.utc
    while date > Time.utc(2013)
      date = (date - 1.month).end_of_month
      # print "----- #{date} -----\n"
      print "#{date},"

      Invoice.where("balance_deduction_amount > ?", 0).for_month(date).each do |invoice|
        user_balances[invoice.user.id] += invoice.balance_deduction_amount
      end

      # print "Active users with balance: #{user_balances.size}\n"
      print "#{user_balances.size},"
      balances_total = number_to_currency(user_balances.values.sum / 100.0, delimiter: "")
      # print "Balances total:            #{balances_total}\n"
      print "#{balances_total}\n"
    end
  end
end
