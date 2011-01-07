class Log::Amazon::S3 < Log::Amazon

  # ====================
  # = Instance Methods =
  # ====================

  def name_matches
    @matches ||= name.match(/^([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-[a-zA-Z0-9]+$/)
  end

private

  # call from name= in Log
  def set_dates_and_hostname_from_name
    if matches = name_matches
      self.started_at ||= Time.zone.parse(matches[1])
      self.ended_at   ||= Time.zone.parse(matches[1]) + 1.day
    end
  end

  # call in Amazon.fetch_new_logs_names
  def self.marker(log, hours = 30.hours)
    date = Time.zone.parse("#{log.name_matches[1]} #{log.name_matches[2]}:#{log.name_matches[3]}:#{log.name_matches[4]}")
    (date - hours).strftime("%Y-%m-%d-%H-%M-%S")
  end

end
