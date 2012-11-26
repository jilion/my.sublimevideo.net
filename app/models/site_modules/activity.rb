module SiteModules::Activity
  extend ActiveSupport::Concern

  def page_visits
    @page_visits ||= Stat::Site::Day.all_time_page_visits(token)
  end

  def views
    @views ||= Stat::Site::Day.views_sum(token: token)
  end

  def billable_views
    @billable_views ||= Stat::Site::Day.views_sum(token: token, billable_only: true)
  end

  private

  def unmemoize_all_activity
    @page_visits    = nil
    @views          = nil
    @billable_views = nil
  end

end
