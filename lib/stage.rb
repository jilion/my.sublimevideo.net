Stage = Struct.new(:stage) do
  STAGES = %w[alpha beta stable]

  def self.stages
    STAGES
  end

  def self.stages_with_access_to(stage)
    case stage
    when 'stable'; %w[stable beta alpha]
    when 'beta'; %w[beta alpha]
    when 'alpha'; %w[alpha]
    end
  end

  def self.version_stage(version)
    case version
    when /alpha/; 'alpha'
    when /beta/; 'beta'
    else; 'stable'
    end
  end

end
