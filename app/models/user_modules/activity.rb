module UserModules::Activity
  extend ActiveSupport::Concern

  module ClassMethods

    def send_inactive_account_email
      User.active.created_on(1.week.ago).find_each(batch_size: 100) do |user|
        UserMailer.delay.inactive_account(user.id) if user.page_visits.zero?
      end
    end

  end

  def page_visits
    @page_visits ||= Stat::Site::Day.all_time_page_visits(sites.not_archived.map(&:token))
  end

  def dev_views
    @dev_views ||= Stat::Site::Day.views_sum(token: sites.not_archived.map(&:token))
  end

  def billable_views
    @billable_views ||= Stat::Site::Day.views_sum(token: sites.not_archived.map(&:token), billable_only: true)
  end

  private

  def unmemoize_all_activity
    @page_visits    = nil
    @dev_views      = nil
    @billable_views = nil
  end

end
