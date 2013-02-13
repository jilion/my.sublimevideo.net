# coding: utf-8
class PeoplePopulator < Populator

  BASE_USERS = {
    mehdi: 'Mehdi Aminian',
    zeno: 'Zeno Crivelli',
    thibaud: 'Thibaud Guillaume-Gentil',
    octave: 'Octave Zangs',
    remy: 'Rémy Coutable',
    andrea: 'Andrea Coiro'
  }
  COUNTRIES  = %w[US FR CH ES DE BE GB CN SE NO FI BR CA]

  def initialize(type = 'users')
    @type = type
  end

  def execute(*args)
    if self.respond_to?(@type)
      send(@type, *args)
    end
  end

  def users(login)
    PopulateHelpers.empty_tables('invoices_transactions', InvoiceItem, Invoice, Transaction, Site, User)

    created_at_array = (Date.new(2011, 1, 1)..100.days.ago.to_date).to_a
    disable_perform_deliveries do
      (login == 'all' ? BASE_USERS : { login => BASE_USERS[login.to_sym] }).each do |login, name|
        email = "#{login}@jilion.com"
        user = User.new(
          email: email,
          password: "123456",
          name: name,
          postal_code: Faker::Address.zip_code,
          country: COUNTRIES.sample,
          billing_name: name,
          billing_address_1: Faker::Address.street_address,
          billing_address_2: Faker::Address.secondary_address,
          billing_postal_code: Faker::Address.zip_code,
          billing_city: Faker::Address.city,
          billing_region: Faker::Address.uk_county,
          billing_country: COUNTRIES.sample,
          use_personal: true,
          terms_and_conditions: "1",
          cc_brand: 'visa',
          cc_full_name: name,
          cc_number: "4111111111111111",
          cc_verification_value: "111",
          cc_expiration_month: 12,
          cc_expiration_year: 2.years.from_now.year
        )
        user.created_at   = created_at_array.sample
        user.confirmed_at = user.created_at
        user.save!
        puts "User #{email}:123456 created!"
      end

      use_personal = false
      use_company  = false
      use_clients  = false
      case rand
      when 0..0.4
        use_personal = true
      when 0.4..0.7
        use_company = true
      when 0.7..1
        use_clients = true
      end
    end
  end

  def admins
    PopulateHelpers.empty_tables(Admin)

    disable_perform_deliveries do
      puts "Creating admins..."
      BASE_USERS.each do |login, name|
        email = "#{login}@jilion.com"
        Admin.create(email: email, password: "123456", roles: ['god'])
        puts "Admin #{email}:123456"
      end
    end
  end

  def enthusiasts
    PopulateHelpers.empty_tables(EnthusiastSite, Enthusiast)

    disable_perform_deliveries do
      BASE_USERS.each do |login, name|
        email = "#{login}@jilion.com"
        enthusiast = Enthusiast.create(email: email, interested_in_beta: true)
        enthusiast.confirmed_at = Time.now
        enthusiast.save!
        print "Enthusiast #{email} created!\n"
      end
    end
  end

  private

  def disable_perform_deliveries(&block)
    if block_given?
      original_perform_deliveries = ActionMailer::Base.perform_deliveries
      # Disabling perform_deliveries (avoid to spam fakes email adresses)
      ActionMailer::Base.perform_deliveries = false

      yield

      # Switch back to the original perform_deliveries
      ActionMailer::Base.perform_deliveries = original_perform_deliveries
    else
      print "\n\nYou must pass a block to this method!\n\n"
    end
  end

end
