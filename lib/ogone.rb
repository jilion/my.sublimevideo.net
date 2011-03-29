module Ogone
  class << self

    def authorize(*args)
      gateway.authorize(*args)
    end

    def void(*args)
      gateway.void(*args)
    end

    def purchase(*args)
      gateway.purchase(*args)
    end

    def credit(money, identification_or_credit_card, options = {})
      refund = gateway.credit(money, identification_or_credit_card, options)
      unless refund.success?
        Notify.send("Refund failed for transaction with pay_id ##{identification_or_credit_card} (amount: #{money})")
      end
      refund
    end

    def sha_out_keys
      %w[AAVADDRESS AAVCHECK AAVZIP ACCEPTANCE ALIAS AMOUNT BIN BRAND CARDNO CCCTY CN COMPLUS CREATION_STATUS
        CURRENCY CVCCHECK DCC_COMMPERCENTAGE DCC_CONVAMOUNT DCC_CONVCCY DCC_EXCHRATE DCC_EXCHRATESOURCE DCC_EXCHRATETS
        DCC_INDICATOR DCC_MARGINPERC ENTAGE DCC_VALIDHOURS DIGESTC ARDNO ECI ED ENCCARDNO IP IPCTY NBREMAILUSAGE
        NBRIPUSAGE NBRIPUSAGE_ALLTX NBRUSAGE NCERROR ORDERID PAYID PM SCO_CATEGORY SCORING STATUS SUBSC RIPTION_ID
        TRXDATE VC]
    end

    def yml
      config_path = Rails.root.join('config', 'ogone.yml')
      @default_storage ||= YAML::load_file(config_path)[Rails.env]
      @default_storage.to_options
    rescue
      raise StandardError, "Ogone config file '#{config_path}' doesn't exist."
    end

  private

    def gateway
      ActiveMerchant::Billing::Base.gateway_mode = Rails.env.production? ? :production : :test
      @@gateway ||= ActiveMerchant::Billing::OgoneGateway.new(yml)
    end

  end
end
