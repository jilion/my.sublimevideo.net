class Stage
  STAGES = %w[stable beta alpha]

  def self.stages
    STAGES
  end

  # Returns the stage that are less stable than the given stage.
  # It includes the given stage.
  #
  # stable => %w[beta alpha]
  # beta   => %w[alpha]
  # alpha  => []
  #
  def self.stages_equal_or_less_stable_than(stage)
    STAGES[STAGES.index(stage)..-1]
  end

  # Returns the stage that are more stable than the given stage.
  # It includes the given stage.
  #
  # stable =>[]
  # beta   => %w[stable]
  # alpha  => %w[stable beta]
  #
  def self.stages_equal_or_more_stable_than(stage)
    STAGES[0..STAGES.index(stage)]
  end

  def self.version_stage(version)
    case version
    when /(alpha|beta)/
      $1
    else
      'stable'
    end
  end

end
