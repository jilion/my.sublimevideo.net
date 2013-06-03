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
require 'populate/trends_populator'

module Populate

  class << self

    def plans
      PopulateHelpers.empty_tables(Plan)
      plans_attributes = [
        { name: "free",       cycle: "none",  video_views: 0,          stats_retention_days: 0,   price: 0,     support_level: 0 },
        { name: "sponsored",  cycle: "none",  video_views: 0,          stats_retention_days: nil, price: 0,     support_level: 0 },
        { name: "trial",      cycle: "none",  video_views: 0,          stats_retention_days: nil, price: 0,     support_level: 2 },
        { name: "plus",       cycle: "month", video_views: 200_000,    stats_retention_days: 365, price: 990,   support_level: 1 },
        { name: "premium",    cycle: "month", video_views: 1_000_000,  stats_retention_days: nil, price: 4990,  support_level: 2 },
        { name: "plus",       cycle: "year",  video_views: 200_000,    stats_retention_days: 365, price: 9900,  support_level: 1 },
        { name: "premium",    cycle: "year",  video_views: 1_000_000,  stats_retention_days: nil, price: 49900, support_level: 2 },
        { name: "custom - 1", cycle: "year",  video_views: 10_000_000, stats_retention_days: nil, price: 99900, support_level: 2 }
      ]
      plans_attributes.each { |attributes| Plan.create!(attributes) }
      puts "#{plans_attributes.size} plans created!"
    end

    def deals
      PopulateHelpers.empty_tables(DealActivation, Deal)
      deals_attributes = [
        { token: 'rts1', name: 'Real-Time Stats promotion #1', description: 'Exclusive Newsletter Promotion: Save 20% on all yearly plans', kind: 'yearly_plans_discount', value: 0.2, availability_scope: 'newsletter', started_at: Time.now.utc.midnight, ended_at: Time.utc(2012, 2, 29).end_of_day },
        { token: 'rts2', name: 'Premium promotion #1', description: '30% discount on the Premium plan', kind: 'premium_plan_discount', value: 0.3, availability_scope: 'newsletter', started_at: 3.weeks.from_now.midnight, ended_at: 5.weeks.from_now.end_of_day }
      ]

      deals_attributes.each { |attributes| Deal.create!(attributes) }
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
      delete_all_files_in_public('uploads/settings', 'uploads/loaders')
      SitesPopulator.new.execute
    end

    def invoices
      InvoicesPopulator.new.execute
    end

    def site_usages
      SiteUsagesPopulator.new.execute
    end

    def video_tags(user_login_or_site_token)
      sites = User.find_by_email!("#{user_login_or_site_token}@jilion.com").sites
    rescue
      sites = [Site.find_by_token(user_login_or_site_token)]
    ensure
      sites.compact.each do |site|
        SiteCountersUpdater.new(site).update_last_30_days_video_tags_counters
      end
    end

    def stats(user_login_or_site_token)
      sites = User.find_by_email!("#{user_login_or_site_token}@jilion.com").sites
    rescue
      sites = [Site.find_by_token(user_login_or_site_token)]
    ensure
      sites.compact.each do |site|
        StatsPopulator.new.execute(site)
      end
    end

    def recurring_stats(site_token)
      RecurringStatsPopulator.new.execute(Site.find_by_token(site_token))
    end

    def trends
      TrendsPopulator.new.execute
    end

    def send_all_emails(user_login)
      EmailsPopulator.new.execute(User.where(email: "#{user_login}@jilion.com").first)
    end

    private

    def delete_all_files_in_public(*paths)
      paths.each do |path|
        if path.gsub('.', '') =~ /\w+/ # don't remove all files and directories in /public ! ;)
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
      end
    end

  end

end
