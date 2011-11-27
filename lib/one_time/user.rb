module OneTime
  module User

    class << self

      def set_name_from_first_and_last_name
        total = 0
        ::User.where { (first_name != nil) & (last_name != nil) & (name == nil) }.find_each(batch_size: 100) do |user|
          user.name = "#{user.first_name} #{user.last_name}"
          user.save!(validate: false)
          total += 1
          puts "#{total} users updated..." if (total % 100) == 0
        end

        "Finished: in total, #{total} users had their name set."
      end

      def set_billing_info
        total = 0
        ::User.where { (name != nil) | (postal_code != nil) | (country != nil) }.find_each(batch_size: 100) do |user|
          user.billing_name        = user.name.presence
          user.billing_postal_code = user.billing_postal_code.presence || user.postal_code.presence
          user.billing_country     = user.billing_country.presence || user.country.presence
          user.save!(validate: false)
          total += 1
          puts "#{total} users updated..." if (total % 100) == 0
        end

        "Finished: in total, #{total} users had their billing info set."
      end

    end

  end
end
