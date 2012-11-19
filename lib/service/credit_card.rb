module Service
  class CreditCard

    def self.send_credit_card_expiration_email
      ::User.paying.cc_expire_this_month
        .last_credit_card_expiration_notice_sent_before(15.days.ago).find_each(batch_size: 100) do |user|
        BillingMailer.delay.credit_card_will_expire(user.id)
      end
    end

  end
end
