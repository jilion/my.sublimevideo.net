class PopulateHelpers

  def self.empty_tables(*tables)
    print "Deleting the content of #{tables.join(', ')}.. => " if Rails.env.development?
    tables.each do |table|
      if table.is_a?(Class)
        table.delete_all
      else
        Site.connection.delete("DELETE FROM #{table} WHERE 1=1")
      end
    end
    puts "#{tables.join(', ')} empty!" if Rails.env.development?
  end

end
