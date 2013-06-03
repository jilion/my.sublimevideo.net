module OgoneWrapper

  STATUS = {
    '46' => :waiting_3d_secure,
    '5'  => :authorized,
    '51' => :waiting,
    '0'  => :invalid,
    '2'  => :refused,
    '1'  => :canceled,
    '52' => :uncertain
  }

  class << self

    %w[store void purchase refund].each do |method_name|
      define_method method_name do |*args|
        begin
          success = gateway.send(method_name, *args)
          Librato.increment "payment_gateway.#{method_name}", source: 'ogone'
          success
        rescue ArgumentError => ex
          Honeybadger.context(
            method: method_name,
            args: args
          )
          raise ex
        end
      end
    end

    def sha_out_keys
      %w[AAVADDRESS AAVCHECK AAVZIP ACCEPTANCE ALIAS AMOUNT BIN BRAND CARDNO CCCTY CN COMPLUS CREATION_STATUS
        CURRENCY CVCCHECK DCC_COMMPERCENTAGE DCC_CONVAMOUNT DCC_CONVCCY DCC_EXCHRATE DCC_EXCHRATESOURCE DCC_EXCHRATETS
        DCC_INDICATOR DCC_MARGINPERC ENTAGE DCC_VALIDHOURS DIGESTC ARDNO ECI ED ENCCARDNO IP IPCTY NBREMAILUSAGE
        NBRIPUSAGE NBRIPUSAGE_ALLTX NBRUSAGE NCERROR ORDERID PAYID PM SCO_CATEGORY SCORING STATUS SUBSC RIPTION_ID
        TRXDATE VC]
    end

    def status
      STATUS
    end

  private

    def gateway
      gateway_config = {
        signature_encryptor:       'sha512',
        created_after_10_may_2010: true,
        currency:                  'USD',
        login:                     "#{ENV['OGONE_LOGIN']}",
        user:                      "#{ENV['OGONE_USER']}",
        password:                  "#{ENV['OGONE_PASSWORD']}",
        signature:                 "#{ENV['OGONE_SIGNATURE']}",
        signature_out:             "#{ENV['OGONE_SIGNATURE_OUT']}"
      }
      @gateway ||= ActiveMerchant::Billing::OgoneGateway.new(gateway_config)
    end

  end
end
