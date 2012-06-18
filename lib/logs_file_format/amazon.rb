# encoding: utf-8

module LogsFileFormat

  MONTHS = {'Jan' => '01', 'Feb' => '02', 'Mar' => '03', 'Apr' => '04', 'May' => '05', 'Jun' => '06',
    'Jul' => '07', 'Aug' => '08', 'Sep' => '09', 'Oct' => '10', 'Nov' => '11', 'Dec' => '12' }

  module Amazon

    def player_token_from(path)
      path.match(/^.*\s\/.*\?t=([a-z0-9]{8})\s.*$/) && $1
    end

    def player_token?(path)
      path =~ /^.*\s\/.*\?t=[a-z0-9]{8}\s.*$/
    end

    def loader_token_from(path)
      path.match(/^\/?loaders\/([a-z0-9]{8})\.js.*/) && $1
    end

    def loader_token?(path)
      path =~ /^\/?loaders\/[a-z0-9]{8}\.js.*/
    end

    def license_token_from(path)
      path.match(/^\/?licenses\/([a-z0-9]{8})\.js.*/) && $1
    end

    def license_token?(path)
      path =~ /^\/?licenses\/[a-z0-9]{8}\.js.*/
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
