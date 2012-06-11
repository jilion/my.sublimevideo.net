require_dependency 'configurator'

module Ogone
  include Configurator

  heroku_config_file 'ogone.yml'

  heroku_config_accessor 'OGONE', :login, :user, :password, :signature, :signature_out

  class << self

    def store(*args)
      gateway.store(*args)
    end

    def void(*args)
      gateway.void(*args)
    end

    def purchase(*args)
      gateway.purchase(*args)
    end

    def refund(*args)
      gateway.refund(*args)
    end

    def sha_out_keys
      %w[AAVADDRESS AAVCHECK AAVZIP ACCEPTANCE ALIAS AMOUNT BIN BRAND CARDNO CCCTY CN COMPLUS CREATION_STATUS
        CURRENCY CVCCHECK DCC_COMMPERCENTAGE DCC_CONVAMOUNT DCC_CONVCCY DCC_EXCHRATE DCC_EXCHRATESOURCE DCC_EXCHRATETS
        DCC_INDICATOR DCC_MARGINPERC ENTAGE DCC_VALIDHOURS DIGESTC ARDNO ECI ED ENCCARDNO IP IPCTY NBREMAILUSAGE
        NBRIPUSAGE NBRIPUSAGE_ALLTX NBRUSAGE NCERROR ORDERID PAYID PM SCO_CATEGORY SCORING STATUS SUBSC RIPTION_ID
        TRXDATE VC]
    end

  private

    def gateway
      ActiveMerchant::Billing::Base.gateway_mode = Rails.env.production? ? :production : :test

      gateway_config = yml_options.merge(login: login, user: user, password: password, signature: signature, signature_out: signature_out)
      @gateway ||= ActiveMerchant::Billing::OgoneGateway.new(gateway_config)
    end

  end
end
