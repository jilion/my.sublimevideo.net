class Stage < Struct.new(:stage)
  STAGES = %w[alpha beta stable]

  def self.version_stage(version)
    case version
    when /alpha/; 'alpha'
    when /beta/; 'beta'
    else; 'stable'
    end
  end

end
