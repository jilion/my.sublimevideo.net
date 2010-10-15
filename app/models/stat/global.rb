class Stat::Global
  include Mongoid::Document
  
  field :day,   :type => Date
  field :vpv,   :type => Hash, :default => { "new" => -1, "total" => -1 }
  field :users, :type => Hash, :default => { "new" => -1, "total" => -1 }
  field :sites, :type => Hash, :default => { "new" => -1, "total" => -1 }
  # field :new_plans, :type => Integer, :default => 0
  # field :tot_plans, :type => Integer, :default => 0
  
  index :day, :unique => true
  
  index([[:day, Mongo::ASCENDING], ['vpv.new', Mongo::ASCENDING]])
  index([[:day, Mongo::ASCENDING], ['vpv.total', Mongo::ASCENDING]])
  index([[:day, Mongo::ASCENDING], ['users.new', Mongo::ASCENDING]])
  index([[:day, Mongo::ASCENDING], ['users.total', Mongo::ASCENDING]])
  index([[:day, Mongo::ASCENDING], ['sites.new', Mongo::ASCENDING]])
  index([[:day, Mongo::ASCENDING], ['sites.total', Mongo::ASCENDING]])
  
  attr_accessible :day, :new, :total, :new_users, :tot_users, :new_sites, :tot_sites
  
  # ===============
  # = Validations =
  # ===============
  validates :day, :presence => true, :uniqueness => true
  
  def self.delay_calculate_all_new(start_day = Date.today, end_day = Date.today, options = {})
    self.delay(:priority => 100).calculate_all_new(start_day, end_day, options)
  end
  
  # Options:
  #   :force => force recalculation of the 'new' counters (heavy work!)
  def self.calculate_all_new(start_day = Date.today, end_day = Date.today, options = {})
    (start_day.to_date..end_day.to_date).each do |day|
      self.calculated_new_fields.each do |field|
        new_field = "#{field}.new"
        next unless !self.already_calculated?(new_field, day) || options[:force]
        self.delay(:priority => 100).calculate(new_field, day, options)
      end
    end
  end
  
  # Calculate and save (or update) the count for the given field on the given day
  # Parameters
  #   field_with_type: the field name and its type, separated by a dot (examples: "vpv.new", "users.total")
  #   day: Date for which you want to calculate (default: Date.today).
  #   options: A Hash of options.
  # 
  # Options:
  #   :force => force recalculation of the counters (heavy work!)
  #
  # Returns the new count for the given field on the given day
  def self.calculate(field_with_type, day = Date.today, options = {})
    return unless !self.already_calculated?(field_with_type, day) || options[:force]
    field, type = field_with_type.split('.')
    calculate_field = "calculate_#{field}"
    self.send(calculate_field, type, day) if self.respond_to?(calculate_field)
  end
  
  def self.calculated_new_fields
    [:vpv]
  end
  
  def self.calculated_total_fields
    [:vpv]
  end
  
  # Always calculate and then save or update the (new or total) VPV on the given day (aka Mongo's "upsert")
  # 
  # Return the new VPV on the given day
  def self.calculate_vpv(type = "new", day = Date.today)
    vpv_this_day = case type.to_s
    when "new"
      SiteUsage.between(day.beginning_of_day, day.end_of_day).sum(self.field_mapping_for_query(:vpv)) || 0
      # Better solution (true upsert but does not work)
      # stat_global_vpv_new_this_day = self.collection.update({ :day => day.beginning_of_day.utc }, { :day => day.beginning_of_day.utc, "vpv.new" => new_vpv_this_day }, { :upsert => true })
    when "total"
      SiteUsage.ended_before(day.end_of_day).sum(self.field_mapping_for_query(:vpv)) || 0
    else
      raise StandardError, "Impossible to calculate vpv on #{day} for the type: #{type}!"
    end
    stat_global_vpv_this_day = self.where(:day => day.beginning_of_day.utc).first || self.new(:day => day.beginning_of_day.utc)
    (stat_global_vpv_this_day.vpv ||= {})[type.to_s] = vpv_this_day
    stat_global_vpv_this_day.save
    vpv_this_day
  end
  
private
  
  def self.already_calculated?(field, day = Date.today)
    self.where(:day => day.to_date, field => { "$gt" => -1, "$ne" => nil }).exists?
  end
  
  def self.field_mapping_for_query(field)
    case field.to_sym
    when :vpv
      'player_hits'
    else
      field.to_s
    end
  end
  
end