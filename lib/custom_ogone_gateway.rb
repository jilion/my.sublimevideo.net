# http://blog.new-bamboo.co.uk/2013/06/13/custom-activemerchant-connections

class CustomOgoneGateway < ActiveMerchant::Billing::OgoneGateway
  class TlsConnection < ActiveMerchant::Connection
    def configure_ssl(http)
      super(http)
      http.ssl_version = :TLSv1
    end
  end

  def new_connection(endpoint)
    TlsConnection.new(endpoint)
  end
end
