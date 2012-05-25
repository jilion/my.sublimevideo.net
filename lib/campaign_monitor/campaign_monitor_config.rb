class CampaignMonitorConfig < Settingslogic
  source "#{Rails.root}/config/campaign_monitor.yml"
  namespace Rails.env
end
