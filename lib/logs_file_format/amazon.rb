module LogsFileFormat
  module Amazon
    
    def token_from(path)
      path.match(/^\/?([a-z0-9]{8})\/.*/) && $1
    end
    
    def token_path?(path)
      path =~ /^\/?[a-z0-9]{8}\/.*/
    end
    
    def s3_get_request?(operation)
      operation.include?("GET") || operation.include?("HEAD")
    end
    
    def us_location?(location)
      [
        "IAD", # Ashburn, VA 
        "DFW", # Dallas/Fort Worth, TX
        "LAX", # Los Angeles, CA
        "MIA", # Miami, FL
        "JFK", # New York, NY
        "EWR", # Newark, NJ
        "SFO", # Palo Alto, CA
        "SEA", # Seattle, WA
        "STL"  # St. Louis, MO
      ].include? location_code(location)
    end
    
    def eu_location?(location)
      [
        "AMS", # Amsterdam
        "DUB", # Dublin
        "FRA", # Frankfurt
        "LHR", # London
      ].include? location_code(location)
    end
    
    def as_location?(location)
      [
        "HKG", # Hong Kong 
        "SIN", # Singapore
      ].include? location_code(location)
    end
    
    def jp_location?(location)
      [
        "NRT", # Tokyo
      ].include? location_code(location)
    end
    
    def unknown_location?(location)
      !us_location?(location) &&
      !eu_location?(location) &&
      !as_location?(location) &&
      !jp_location?(location)
    end
    
  private
    
    def location_code(location)
      location.match(/^([A-Z]+)[0-9]+$/) && $1
    end
    
  end
end
