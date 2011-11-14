class Vat < Settingslogic
  source "#{Rails.root}/config/vat.yml"

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
