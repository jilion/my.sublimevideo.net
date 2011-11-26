class Optimizely < Settingslogic
  source "#{Rails.root}/config/optimizely.yml"
  namespace Rails.env
end