module Ogone
  class << self
    extend ActiveSupport::Memoizable

    def method_missing(name, *args)
      gateway.send(name, *args)
    end

    def keys_used_for_sha_out
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
      ActiveMerchant::Billing::Base.gateway_mode = :test
      Rails.logger.info "Ogone.gateway_mode: #{ActiveMerchant::Billing::Base.gateway_mode}"
      ActiveMerchant::Billing::OgoneGateway.new(yml)
    end
    memoize :gateway

  end
end
