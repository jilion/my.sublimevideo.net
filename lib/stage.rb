Stage = Struct.new(:stage) do
  self::STAGES = %w[alpha beta stable]

  def self.version_stage(version)
    case version
    when /alpha/; 'alpha'
    when /beta/; 'beta'
    else; 'stable'
    end
  end

end
