module OgoneWrapper
  include Configurator

  config_file 'ogone.yml'
  config_accessor :login, :user, :password, :signature, :signature_out, :signature_encryptor, :created_after_10_may_2010, :currency, :status

  class << self

    %w[store void purchase refund].each do |method_name|
      define_method method_name do |*args|
        Librato.increment "payment_gateway.#{method_name}", source: 'ogone'
        gateway.send(method_name, *args)
      end
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
      gateway_config = {
        signature_encryptor: signature_encryptor,
        created_after_10_may_2010: created_after_10_may_2010,
        currency: currency,
        login: login,
        user: user,
        password: password,
        signature: signature,
        signature_out: signature_out,
        store_amount: 100
      }
      @gateway ||= ActiveMerchant::Billing::OgoneGateway.new(gateway_config)
    end

  end
end
