# encoding: utf-8
module Trend
  extend ActiveSupport::Concern

  included do
    field :d, type: DateTime

    index({ d: 1 }, { unique: true })

    default_scope -> { order_by(d: 1) }
  end

  # send time as id for backbonejs model
  def as_json(options = nil)
    json = super
    json['id'] = d.to_i
    json
  end

  module ClassMethods
    def json(from = nil, to = nil)
      json_trends = if from.present?
        between(d: from..(to || Time.now.utc.midnight))
      else
        all
      end

      json_trends.order_by(d: 1).to_json(only: self.json_fields)
    end

    def create_trends
      last_trend_day = determine_last_trend_day

      while last_trend_day < 1.day.ago.midnight do
        last_trend_day += 1.day
        create_trend(last_trend_day)
      end
    end

    def create_trend(day)
      self.create(trend_hash(day))
    end

    def determine_last_trend_day
      raise NotImplementedError, "This #{self.class} cannot respond to:"
    end

    def trend_hash(day)
      raise NotImplementedError, "This #{self.class} cannot respond to:"
    end

    def json_fields
      raise NotImplementedError, "This #{self.class} cannot respond to:"
    end
  end

end
