# coding: utf-8
require_dependency 'time_util'
require_dependency 'populate'

namespace :db do

  desc "Load all development fixtures."
  task populate: ['populate:empty_all_tables', 'populate:all']

  namespace :populate do
    desc "Empty all the tables"
    task empty_all_tables: :environment do
      Rails.cache.clear
      timed { Populate.empty_tables("invoices_transactions", DealActivation, Deal, InvoiceItem, Invoice, Transaction, Log, MailTemplate, MailLog, Site, SiteUsage, User, Admin, Plan) }
    end

    desc "Load all development fixtures."
    task all: :environment do
      Populate.delete_all_files_in_public('uploads/releases', 'uploads/s3', 'uploads/tmp', 'uploads/voxcast')
      timed { Populate.plans }
      timed { Populate.addons }
      timed { Populate.admins }
      timed { Populate.users(argv('user')) }
      timed { Populate.sites }
      timed { Populate.invoices }
      timed { Populate.site_usages }
      timed { Populate.site_stats }
      timed { Populate.users_stats }
      timed { Populate.sites_stats }
      timed { Populate.sales_stats }
      # timed { Populate.deals }
      timed { Populate.mail_templates }
      # timed { Populate.player_components }
    end

    desc "Load Admin development fixtures."
    task admins: :environment do
      timed { Populate.admins }
    end

    desc "Load Enthusiast development fixtures."
    task enthusiasts: :environment do
      timed { Populate.enthusiasts(argv('user')) }
    end

    desc "Load User development fixtures."
    task users: :environment do
      timed { Populate.users(argv('user')) }
    end

    desc "Load Site development fixtures."
    task sites: :environment do
      timed { Populate.sites }
    end

    desc "Load Site development fixtures."
    task invoices: :environment do
      timed { Populate.invoices(argv('user')) }
    end

    desc "Load Deals development fixtures."
    task deals: :environment do
      timed { Populate.deals }
    end

    desc "Load Mail templates development fixtures."
    task mail_templates: :environment do
      timed { Populate.mail_templates }
    end

    desc "Create fake usages"
    task site_usages: :environment do
      timed { Populate.site_usages }
    end

    desc "Create fake site stats"
    task site_stats: :environment do
      timed { Populate.site_stats(argv('user')) }
    end

    desc "Create fake site stats"
    task recurring_site_stats: :environment do
      timed { Populate.site_stats(argv('user')) }
      timed { Populate.recurring_site_stats_update(argv('user')) }
    end

    desc "Create fake site & video stats"
    task stats: :environment do
      timed { Populate.stats(argv('site')) }
    end

    desc "Create recurring fake site & video stats"
    task recurring_stats: :environment do
      timed { Populate.recurring_stats_update(argv('site')) }
    end

    desc "Create fake users & sites stats for the admin dashboard"
    task admin_stats: :environment do
      timed { Populate.users_stats }
      timed { Populate.sites_stats }
      timed { Populate.sales_stats }
    end

    desc "Create fake plans"
    task plans: :environment do
      timed { Populate.plans }
    end

    desc "Create fake addons"
    task addons: :environment do
      timed { Populate.addons }
    end

    # desc "Create fake player components"
    # task player_components: :environment do
    #   timed { Populate.player_components }
    # end

    desc "Create fake video_tags"
    task video_tags: :environment do
      timed { Populate.video_tags(argv('site')) }
    end

    desc "Send emails (via letter_opener)"
    task emails: :environment do
      timed { Populate.send_all_emails(argv('user')) }
    end

    desc "Import MongoDB production databases locally (not the other way around don't worry!)"
    task import_mongo_prod: :environment do
      mongo_db_pwd = argv('password')
      raise "Please provide a password to access the production database like this: rake db:populate:import_mongo_prod password=MONGOHQ_PASSWORD" if mongo_db_pwd.nil?

      %w[sales_stats site_stats_stats site_usages_stats sites_stats tweets_stats users_stats tweets].each do |collection|
        timed do
          puts "Exporting production '#{collection}' collection"
          `mongodump -h sublimevideo.member0.mongolayer.com:27017 -d sublimevideo-stats -u heroku -p #{mongo_db_pwd} -o db/backups/ --collection #{collection}`
          puts "Importing '#{collection}' collection locally"
          `mongorestore -h localhost -d sublimevideo_dev --collection #{collection} --drop -v db/backups/sublimevideo-stats/#{collection}.bson`
        end
      end
    end
  end

end

namespace :user do

  desc "Expire the credit card of the user with the given email (EMAIL=xx@xx.xx) at the end of the month (or the opposite if already expiring at the end of the month)"
  task cc_will_expire: :environment do
    timed do
      email = argv("email")
      return if email.nil?

      User.find_by_email(email).tap do |user|
        date = if user.cc_expire_on == TimeUtil.current_month.last.to_date
          puts "Update credit card for #{email}, make it expire in 2 years..."
          2.years.from_now
        else
          puts "Update credit card for #{email}, make it expire at the end of the month..."
          TimeUtil.current_month.last
        end
        user.update_attributes({
          cc_type: 'visa',
          cc_full_name: user.name,
          cc_number: "4111111111111111",
          cc_verification_value: "111",
          cc_expire_on: date
        })
      end
    end
  end

  desc "Suspend/unsuspend a user given an email (EMAIL=xx@xx.xx), you can pass the count of failed invoices on suspend with FAILED_INVOICES=N"
  task suspended: :environment do
    timed do
      email = argv("email")
      return if email.nil?

      User.find_by_email(email).tap do |user|
        if user.suspended?
          puts "Unsuspend #{email}..."
          user.update_attribute(:state, 'active')
        else
          puts "Suspend #{email}..."
          user.update_attribute(:state, 'suspended')
        end
      end
    end
  end

end

namespace :sm do

  desc "Draw the States Diagrams for every model having State Machine"
  task draw: :environment do
    %x(rake state_machine:draw CLASS=Invoice,Log,Site,User TARGET=doc/state_diagrams FORMAT=png ORIENTATION=landscape)
  end

end

private

def argv(var_name, default = nil)
  if var = ARGV.detect { |arg| arg =~ /(#{var_name}=)/i }
    var.sub($1, '')
  else
    default
  end
end
