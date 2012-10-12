Stage = Struct.new(:stage) do
  STAGES = %w[alpha beta stable] unless defined? STAGES

  def self.version_stage(version)
    case version
    when /alpha/; 'alpha'
    when /beta/; 'beta'
    else; 'stable'
    end
  end

end
