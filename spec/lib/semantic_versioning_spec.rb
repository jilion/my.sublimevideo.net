require "fast_spec_helper"

require File.expand_path('lib/semantic_versioning')

class Version < Struct.new(:version)
  include SemanticVersioning

  def initialize(version_string)
    self.version = version_string
  end
end

describe SemanticVersioning do

  describe "#version" do
    # Valid
    {
      '*' => '*',
      '0.0.0'  => '0.0.0',
      '1.2.3'  => '1.2.3',
      '1.2.3-'  => '1.2.3',
      '1.2.3-alpha'   => '1.2.3-alpha.0',
      '1.2.3-alpha1'  => '1.2.3-alpha.1',
      '1.2.3-alpha.2' => '1.2.3-alpha.2',
      '1.2.3-x'       => '1.2.3-x.0',
      '1.2.3-Alpha.2' => '1.2.3-alpha.2'
    }.each do |input, result|
      it "'#{input}' gives '#{result}'" do
        Version.new(input).version.should eq(result)
      end
    end

    # Invalid
    [
      nil,
      '',
      'x',
      '0.*',
      '0.1',
      '1',
      '1.2',
      '1.x',
      '1.2.x',
      '1.2.*',
      '*.x.*',
      'x.x.x',
      '*.*.*',
      '1.*.*',
      '1.x.x',
      '1.2.3-*',
      '1.2.3-*',
      '1.2.3-alpha*',
      '1.2.3-alpha.*',
      '1.2.3-alpha.x'
    ].each do |invalid_version|
      it "'#{invalid_version}' is invalid" do
        expect { Version.new(invalid_version) }.to raise_error(InvalidVersion)
      end
    end
  end

  describe "#version_inc" do
    {
      major: {
        '*' => '*',
        '0.0.1' => '1.0.0',
        '0.4.0' => '1.0.0',
        '1.0.0' => '2.0.0',
        '1.2.3-alpha.2' => '2.0.0'
      },
      minor: {
        '*' => '*',
        '0.0.1' => '0.1.0',
        '0.4.0' => '0.5.0',
        '1.0.0' => '1.1.0',
        '1.2.3-alpha.2' => '1.3.0'
      },
      patch: {
        '*' => '*',
        '0.0.1' => '0.0.2',
        '0.4.0' => '0.4.1',
        '1.0.0' => '1.0.1',
        '1.2.3-alpha.2' => '1.2.4'
      },
      build: {
        '*' => '*',
        '0.0.1' => '0.0.1',
        '0.4.0' => '0.4.0',
        '1.0.0' => '1.0.0',
        '1.2.3-alpha' => '1.2.3-alpha.1',
        '1.2.3-alpha.2' => '1.2.3-alpha.3'
      }
    }.each do |release, hash|
      context "with #{release} release" do
        hash.each do |version, result|
          it "increments '#{version}' to '#{result}'" do
            v = Version.new(version)
            v.version_inc(release)
            v.version.should eq(result)
          end
        end
      end
    end
  end

  describe "comparaison" do
    it "compares with simple version" do
      v200 = Version.new('2.0.0')
      v124 = Version.new('1.2.4')
      v123 = Version.new('1.2.3')
      v130 = Version.new('1.3.0')
      [v200, v124, v130, v123].sort.should eq([
        v123, v124, v130, v200
      ])
    end

    it "compares with complex version" do
      v100_aplha1 = Version.new('1.0.0-alpha.1')
      v100_beta2 = Version.new('1.0.0-beta.2')
      v100 = Version.new('1.0.0')
      vinf = Version.new('*')
      [v100, vinf, v100_aplha1, v100_beta2].sort.should eq([
        v100_aplha1, v100_beta2, v100, vinf
      ])
    end
  end

  describe "ranges" do
    {
      '1.0.0' => '1.0.0'..'2.0.0',
      '1.2.0' => '1.0.0'..'2.0.0',
      '1.1.1' => '1.1.0'..'1.2.0',
      '2.0.0' => '1.0.0'..'2.0.0',
      '3.0.0' => '1.0.0'..'*',
    }.each do |version, range|
      it "'#{version}' is between #{range}" do
        Version.new(version).between?(
          Version.new(range.first),
          Version.new(range.last)
        ).should be_true
      end
    end

    {
      '*'     => '1.0.0'..'2.0.0',
      '0.0.1' => '1.0.0'..'2.0.0',
      '3.0.0' => '1.0.0'..'2.0.0',
      '1.3.5' => '1.0.0'..'1.3.4',
      '0.1.0' => '1.0.0'..'*',
    }.each do |version, range|
      it "'#{version}' isn't between #{range}" do
        Version.new(version).between?(
          Version.new(range.first),
          Version.new(range.last)
        ).should be_false
      end
    end
  end

  describe ".dependency_range" do
    {
      '*' => '0.0.0'..'*',
      '1' => '1.0.0'..'2.0.0',
      '~1' => '1.0.0'..'2.0.0',
      '1.x' => '1.0.0'..'2.0.0',
      '1.2' => '1.2.0'..'1.3.0',
      '~1.2' => '1.2.0'..'1.3.0',
      '1.x.x' => '1.0.0'..'2.0.0',
      '1.2.x' => '1.2.0'..'1.3.0',
      '1.2.3' => '1.2.3'..'1.2.4',
      '~1.2.3' => '1.2.3'..'1.3.0',
      '>=1.2.3' => '1.2.3'..'*',
      '1.2.3-alpha' => '1.2.3-alpha.0'..'1.2.3-alpha.1',
      '~1.2.3-alpha' => '1.2.3-alpha.0'..'1.2.4',
      '>=1.2.3-alpha' => '1.2.3-alpha.0'..'*',
      '1.2.3-alpha.x' => '1.2.3-alpha.0'..'1.2.4',
      '1.2.3-alpha.1' => '1.2.3-alpha.1'..'1.2.3-alpha.2',
      '~1.2.3-alpha.1' => '1.2.3-alpha.1'..'1.2.4',
      '>=1.2.3-alpha.1' => '1.2.3-alpha.1'..'*',
    }.each do |identifier, exculsive_range|
      it "'#{identifier}' dependency syntax gives #{exculsive_range} range (exclusive)" do
        dependency_range = Version.dependency_range(identifier)
        dependency_range.first.version.should eq exculsive_range.first
        dependency_range.last.version.should eq exculsive_range.last
      end
    end
  end


end
