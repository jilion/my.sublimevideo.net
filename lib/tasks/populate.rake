# coding: utf-8
require 'populate'

namespace :db do

  desc "Load all development fixtures."
  task populate: ['populate:clear', 'populate:all']

  namespace :populate do
    desc "Empty all the tables"
    task clear: :environment do
      Rails.cache.clear
      Sidekiq.redis { |con| con.flushall }
      timed { PopulateHelpers.empty_tables('invoices_transactions', DealActivation, Deal, InvoiceItem, Invoice, Transaction, Log, MailTemplate, MailLog, Site, User, Admin, Plan) }
    end

    desc "Load all development fixtures. e.g.: rake 'db:populate:all[remy]'"
    task :all, [:login] => [:environment] do |t, args|
      timed { Populate.plans }
      timed { Populate.addons }
      timed { Populate.admins }
      timed { Populate.users(args.login) }
      timed { Populate.sites }
      timed { Populate.invoices }
      timed { Populate.trends }
      timed { Populate.feedbacks }
      # timed { Populate.deals }
      timed { Populate.mail_templates }
    end

    desc "Create fake plans"
    task plans: :environment do
      timed { Populate.plans }
    end

    desc "Create fake addons"
    task addons: :environment do
      timed { Populate.addons }
    end

    desc "Load Admin development fixtures."
    task admins: :environment do
      timed { Populate.admins }
    end

    desc "Load Enthusiast development fixtures."
    task enthusiasts: :environment do
      timed { Populate.enthusiasts }
    end

    desc "Load User development fixtures. e.g.: rake 'db:populate:users[remy]'"
    task :users, [:login] => [:environment] do |t, args|
      timed { Populate.users(args.login) }
    end

    desc "Load Site development fixtures."
    task sites: :environment do
      timed { Populate.sites }
    end

    desc "Load Site development fixtures."
    task invoices: :environment do
      timed { Populate.invoices }
    end

    desc "Create fake trends for the admin dashboard"
    task trends: :environment do
      timed { Populate.trends }
    end

    desc "Create fake feedbacks"
    task feedbacks: :environment do
      timed { Populate.feedbacks }
    end

    desc "Load Deals development fixtures."
    task deals: :environment do
      timed { Populate.deals }
    end

    desc "Load Mail templates development fixtures."
    task mail_templates: :environment do
      timed { Populate.mail_templates }
    end

    desc "Send emails (via letter_opener). e.g.: rake 'db:populate:emails[remy]'"
    task :emails, [:login] => [:environment] do |t, args|
      timed { Populate.send_all_emails(args.login) }
    end
  end

end

namespace :user do

  desc "Expire the credit card of the user with the given email (EMAIL=xx@xx.xx) at the end of the month (or the opposite if already expiring at the end of the month)"
  task cc_will_expire: :environment do
    timed do
      email = argv("email")
      return if email.nil?

      User.where(email: email).first.tap do |user|
        date = if user.cc_expire_on == Time.now.utc.end_of_month.to_date
          puts "Update credit card for #{email}, make it expire in 2 years..."
          2.years.from_now
        else
          puts "Update credit card for #{email}, make it expire at the end of the month..."
          Time.now.utc.end_of_month.to_date
        end
        user.update({
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

      User.where(email: email).first.tap do |user|
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
  if var = ARGV.find { |arg| arg =~ /(#{var_name}=)/i }
    var.sub($1, '')
  else
    ARGV.try(:[], 1)
  end
end
