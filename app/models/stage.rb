class Stage
  STAGES = %w[stable beta alpha]

  def self.stages
    STAGES
  end

  # Returns the given stage + the stages that are less stable
  # than the given stage.
  #
  # @example Given the beta stage
  #   Stage.stages_equal_or_more_stable_than('beta') #=> %w[beta alpha]
  #
  def self.stages_equal_or_less_stable_than(stage)
    STAGES[STAGES.index(stage)..-1]
  end

  # Returns the given stage + the stages that are more stable
  # than the given stage.
  #
  # @example Given the beta stage
  #   Stage.stages_equal_or_more_stable_than('beta') #=> %w[stable beta]
  #
  def self.stages_equal_or_more_stable_than(stage)
    STAGES[0..STAGES.index(stage)]
  end

  # Returns the stage for a given version.
  #
  # @example A stable version
  #   Stage.version_stage('1.0') #=> 'stable'
  # @example A beta version
  #   Stage.version_stage('1.1-beta') #=> 'beta'
  # @example An alpha version
  #   Stage.version_stage('2.0-alpha') #=> 'alpha'
  #
  def self.version_stage(version)
    case version
    when /(alpha|beta)/
      $1
    else
      'stable'
    end
  end

end
