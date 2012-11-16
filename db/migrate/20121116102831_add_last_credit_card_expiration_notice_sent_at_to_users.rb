class AddLastCreditCardExpirationNoticeSentAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_credit_card_expiration_notice_sent_at, :datetime
  end
end
