require 'activemerchant'
require 'custom_ogone_gateway'

module OgoneWrapper

  STATUS = {
    '0'  => :invalid,
    '1'  => :canceled,
    '2'  => :refused, # auth refused
    '5'  => :authorized,
    '9'  => :requested,
    '46' => :waiting_3d_secure,
    '51' => :waiting, # auth waiting
    '52' => :uncertain, # auth unknown
    '92' => :uncertain, # payment uncertain
    '93' => :refused # payment refused
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

  end

  def self.sha_out_keys
    %w[AAVADDRESS AAVCHECK AAVZIP ACCEPTANCE ALIAS AMOUNT BIN BRAND CARDNO CCCTY CN COMPLUS CREATION_STATUS
      CURRENCY CVCCHECK DCC_COMMPERCENTAGE DCC_CONVAMOUNT DCC_CONVCCY DCC_EXCHRATE DCC_EXCHRATESOURCE DCC_EXCHRATETS
      DCC_INDICATOR DCC_MARGINPERC ENTAGE DCC_VALIDHOURS DIGESTC ARDNO ECI ED ENCCARDNO IP IPCTY NBREMAILUSAGE
      NBRIPUSAGE NBRIPUSAGE_ALLTX NBRUSAGE NCERROR ORDERID PAYID PM SCO_CATEGORY SCORING STATUS SUBSC RIPTION_ID
      TRXDATE VC]
  end

  def self.status
    STATUS
  end

  def self.gateway
    gateway_config = {
      signature_encryptor:       'sha512',
      created_after_10_may_2010: true,
      currency:                  'USD',
      login:                     ENV['OGONE_LOGIN'],
      user:                      ENV['OGONE_USER'],
      password:                  ENV['OGONE_PASSWORD'],
      signature:                 ENV['OGONE_SIGNATURE'],
      signature_out:             ENV['OGONE_SIGNATURE_OUT']
    }
    ActiveMerchant::Billing::Base.mode = :test unless Rails.env == 'production'
    @@_gateway ||= CustomOgoneGateway.new(gateway_config)
  end

end
