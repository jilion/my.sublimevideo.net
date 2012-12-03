require_dependency 'configurator'

class Vat
  include Configurator

  config_file 'vat.yml', rails_env: false
  config_accessor :ch

  def self.for_country(country)
    case country
    when 'CH'
      Vat.ch
    else
      0.0
    end
  end

  def self.for_country?(country)
    for_country(country) > 0
  end

end
