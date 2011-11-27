module OneTime
  module User

    class << self

      def set_name_from_first_and_last_name
        total = 0
        ::User.where { (first_name != nil) & (last_name != nil) & (name == nil) }.find_each(batch_size: 100) do |user|
          user.update_attribute(:name, user.first_name.to_s + ' ' + user.last_name.to_s)
          total += 1
          puts "#{total} users updated..." if (total % 100) == 0
        end

        "Finished: in total, #{total} users had their name set."
      end

      def set_billing_info
        total = 0
        ::User.where { (name != nil) | (postal_code != nil) | (country != nil) }.find_each(batch_size: 100) do |user|
          user.update_attributes(billing_name: user.name.presence, billing_postal_code: user.billing_postal_code.presence || user.postal_code.presence, billing_country: user.billing_country.presence || user.country.presence)
          total += 1
          puts "#{total} users updated..." if (total % 100) == 0
        end

        "Finished: in total, #{total} users had their billing info set."
      end

    end

  end
end
