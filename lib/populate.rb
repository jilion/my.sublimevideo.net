# coding: utf-8
require 'ffaker' if Rails.env.development?
require 'populate/populator'
require 'populate/populate_helpers'
require 'populate/stats_populator'
require 'populate/addon_plan_settings_populator'
require 'populate/addon_system_populator'
require 'populate/emails_populator'
require 'populate/people_populator'
require 'populate/invoices_populator'
require 'populate/recurring_stats_populator'
require 'populate/sites_populator'
require 'populate/feedbacks_populator'
require 'populate/trends_populator'

module Populate

  class << self

    def plans
      PopulateHelpers.empty_tables(Plan)
      keys = [:name, :cycle, :video_views, :stats_retention_days, :price, :support_level]
      plans_attributes = [
        ["free",       "none",  0,          0,   0,     0],
        ["sponsored",  "none",  0,          nil, 0,     0],
        ["trial",      "none",  0,          nil, 0,     2],
        ["plus",       "month", 200_000,    365, 990,   1],
        ["premium",    "month", 1_000_000,  nil, 4990,  2],
        ["plus",       "year",  200_000,    365, 9900,  1],
        ["premium",    "year",  1_000_000,  nil, 49900, 2],
        ["custom - 1", "year",  10_000_000, nil, 99900, 2]
      ]

      plans_attributes.each { |attrs| Plan.create!(Hash[keys.zip(attrs)]) }
      puts "#{plans_attributes.size} plans created!"
    end

    def deals
      PopulateHelpers.empty_tables(DealActivation, Deal)
      keys = [:token, :name, :description, :kind, :value, :availability_scope, :started_at, :ended_at]
      deals_attributes = [
        ['rts1', 'Real-Time Stats promotion #1', 'Exclusive Newsletter Promotion: Save 20% on all yearly plans', 'yearly_plans_discount', 0.2, 'newsletter', Time.now.utc.midnight, Time.utc(2012, 2, 29).end_of_day],
        ['rts2', 'Premium promotion #1', '30% discount on the Premium plan', 'premium_plan_discount', 0.3, 'newsletter', 3.weeks.from_now.midnight, 5.weeks.from_now.end_of_day]
      ]

      deals_attributes.each { |attrs| Deal.create!(Hash[keys.zip(attrs)]) }
      puts "#{deals_attributes.size} deals created!"
    end

    def addons
      AddonSystemPopulator.new.execute
    end

    def mail_templates(count = 5)
      PopulateHelpers.empty_tables(MailTemplate)
      count.times do |i|
        MailTemplate.create(
          title: Faker::Lorem.sentence(1),
          subject: Faker::Lorem.sentence(1),
          body: Faker::Lorem.paragraphs(3).join("\n\n")
        )
      end
      puts "#{count} random mail templates created!"
    end

    def admins
      PeoplePopulator.new('admins').execute
    end

    def enthusiasts
      PeoplePopulator.new('enthusiasts').execute
    end

    def users(user_login)
      PeoplePopulator.new('users').execute(user_login)
    end

    def sites
      Populate.users if User.all.empty?
      Populate.plans if Plan.all.empty?
      _delete_all_files_in_public('uploads/settings', 'uploads/loaders')
      SitesPopulator.new.execute
    end

    def invoices
      InvoicesPopulator.new.execute
    end

    def site_usages
      SiteUsagesPopulator.new.execute
    end

    def video_tags(user_login_or_site_token)
      _sites_from_user_login_or_site_token(user_login_or_site_token).each do |site|
        SiteCountersUpdater.new(site).update_last_30_days_video_tags_counters
      end
    end

    def stats(user_login_or_site_token)
      _sites_from_user_login_or_site_token(user_login_or_site_token).each do |site|
        StatsPopulator.new.execute(site)
      end
    end

    def recurring_stats(site_token)
      RecurringStatsPopulator.new.execute(Site.where(token: site_token).first)
    end

    def feedbacks
      FeedbacksPopulator.new.execute
    end

    def trends
      TrendsPopulator.new.execute
    end

    def send_all_emails(user_login)
      EmailsPopulator.new.execute(User.where(email: "#{user_login}@jilion.com").first)
    end

    private

    def _sites_from_user_login_or_site_token(user_login_or_site_token)
      User.where(email: "#{user_login_or_site_token}@jilion.com").first!.sites
    rescue
      [Site.where(token: user_login_or_site_token).first]
    end

    def _delete_file_in_public(path)
      print "Deleting all files and directories in /public/#{path}\n" if Rails.env.development?
      timed do
        Dir["#{Rails.public_path}/#{path}/**/*"].each do |filename|
          File.delete(filename) if File.file?(filename)
        end
        Dir["#{Rails.public_path}/#{path}/**/*"].each do |filename|
          Dir.delete(filename) if File.directory?(filename)
        end
      end
    end

    def _delete_all_files_in_public(*paths)
      paths.each do |path|
        _delete_file_in_public(path) unless ['.', '..'].include?(path)
      end
    end

  end

end
