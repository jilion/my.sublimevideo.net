require 'active_merchant'

ActiveMerchant::Billing::Base.mode = :test unless Rails.env.production?
