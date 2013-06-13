class Vat

  def self.for_country(country)
    case country
    when 'CH'
      0.08
    else
      0.0
    end
  end

  def self.for_country?(country)
    for_country(country) > 0
  end

end
