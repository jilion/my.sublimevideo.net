module OneTime
  module User

    class << self

      def set_name_from_first_and_last_name
        total = 0
        ::User.where { (first_name != nil) & (last_name != nil) }.find_each(batch_size: 100) do |user|
          user.update_attribute(:name, user.first_name.to_s + ' ' + user.last_name.to_s)
          total += 1
        end
        "Finished: in total, #{total} users had their name set."
      end

      def set_billing_address_from_current_infos
        total = 0
        ::User.where { name != nil }.find_each(batch_size: 100) do |user|
          user.update_attribute(:billing_name, user.name)
          total += 1
        end
        "Finished: in total, #{total} users had their billing address set."
      end

    end

  end
end
