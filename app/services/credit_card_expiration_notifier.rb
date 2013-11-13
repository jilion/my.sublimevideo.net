class CreditCardExpirationNotifier

  def self.send_emails
    User.paying.cc_expire_this_month
      .last_credit_card_expiration_notice_sent_before(15.days.ago).find_each(batch_size: 100) do |user|
      BillingMailer.delay(queue: 'my').credit_card_will_expire(user.id)
    end
  end

end
