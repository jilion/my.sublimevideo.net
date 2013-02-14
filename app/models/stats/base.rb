module Stats
  class Base
    include Mongoid::Document
    include Mongoid::Timestamps

    field :d, type: DateTime # Day

    # send time as id for backbonejs model
    def as_json(options = nil)
      json = super
      json['id'] = d.to_i
      json
    end

    def self.json(from = nil, to = nil)
      json_stats = if from.present?
        between(d: from..(to || Time.now.utc.midnight))
      else
        scoped
      end

      json_stats.order_by(d: 1).to_json(only: self.json_fields)
    end

    def self.create_stats
      last_stat_day = determine_last_stat_day

      while last_stat_day < 1.day.ago.midnight do
        last_stat_day += 1.day
        create_stat(last_stat_day)
      end
    end

    def self.create_stat(day)
      self.create(stat_hash(day))
    end

    def self.determine_last_stat_day
      raise NotImplementedError, '.determine_last_stat_day must be implemented in the subclass of Stats::Base'
    end

    def self.stat_hash(day)
      raise NotImplementedError, '.stat_hash must be implemented in the subclass of Stats::Base'
    end

    def self.json_fields
      raise NotImplementedError, '.json_fields must be implemented in the subclass of Stats::Base'
    end

  end
end
