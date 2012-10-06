# SemanticVersioning need a version attribute
# https://npmjs.org/doc/json.html#version

require 'active_support/core_ext'

class InvalidVersion < StandardError; end

module SemanticVersioning
  extend ActiveSupport::Concern
  include Comparable

  attr_accessor :version_hash

  included do
    def version=(string)
      set_version_hash(string)
      self[:version] = version
    end

    def version
      return self[:version] if version_hash.nil?
      return '*' if any_version?
      version = [
        version_hash[:major],
        version_hash[:minor],
        version_hash[:patch]
      ].join('.')
      if version_hash[:name]
        version = [ version,
          [version_hash[:name], version_hash[:build]].join('.'),
        ].join('-')
      end
      version
    end

    def version_inc(release)
      return if any_version?
      case release
      when :major
        self.version_hash[:major] += 1
        self.version_hash[:minor] = 0
        self.version_hash[:patch] = 0
        self.version_hash[:name]  = nil
        self.version_hash[:build] = 0
      when :minor
        self.version_hash[:minor] += 1
        self.version_hash[:patch] = 0
        self.version_hash[:name]  = nil
        self.version_hash[:build] = 0
      when :patch
        self.version_hash[:patch] += 1
        self.version_hash[:name]  = nil
        self.version_hash[:build] = 0
      when :build
        if version_hash[:name]
          self.version_hash[:build] += 1
        end
      end
      self[:version] = version
      self
    end

    def any_version?
      version_hash && version_hash[:major] == Float::INFINITY
    end

    def self.dependency_range(identifier)
      case identifier
      when '*'
        min = self.new('0.0.0')
        max = self.new('*')
      when /^~?(\d)(\.x.*)?$/
        min = self.new("#{$1}.0.0")
        max = self.new(min.version).version_inc(:major)
      when /^~?(\d)\.(\d)(\.x)?$/
        min = self.new("#{$1}.#{$2}.0")
        max = self.new(min.version).version_inc(:minor)
      when /^(\d)\.(\d).(\d)$/
        min = self.new("#{$1}.#{$2}.#{$3}")
        max = self.new(min.version).version_inc(:patch)
      when /^~(\d)\.(\d).(\d)$/
        min = self.new("#{$1}.#{$2}.#{$3}")
        max = self.new(min.version).version_inc(:minor)
      when /^(\d)\.(\d).(\d)-([a-z]+)\.x$/
        min = self.new("#{$1}.#{$2}.#{$3}-#{$4}")
        max = self.new(min.version).version_inc(:patch)
      when /^(\d)\.(\d).(\d)-?([a-z]+)?\.?(\d)?$/
        min = self.new("#{$1}.#{$2}.#{$3}-#{$4}.#{$5}")
        max = self.new(min.version).version_inc(:build)
      when /^~(\d)\.(\d).(\d)-([a-z]+)\.?(\d)?$/
        min = self.new("#{$1}.#{$2}.#{$3}-#{$4}.#{$5}")
        max = self.new(min.version).version_inc(:patch)
      when /^>=(\d)\.(\d).(\d)-?([a-z]+)?\.?(\d)?$/
        min = self.new("#{$1}.#{$2}.#{$3}-#{$4}.#{$5}")
        max = self.new('*')
      end
      Range.new(min, max, true) # exclusive
    end

  private

    VERSION_REGEX = /^
      (\d+)\.      # major
      (\d+)\.      # minor
      (\d+)        # patch
      -?           # separation
      ([a-z]+)?\.? # name
      (\d+)?       # build
    $/ix

    def set_version_hash(version)
      self.version_hash = {}
      case version
      when '*'
        self.version_hash[:major] = Float::INFINITY
      when VERSION_REGEX
        self.version_hash[:major] = $1.to_i
        self.version_hash[:minor] = $2.to_i
        self.version_hash[:patch] = $3.to_i
        if $4
          self.version_hash[:name] = $4.downcase
          self.version_hash[:build] = $5.to_i
        end
      else
        raise InvalidVersion
      end
    end

    def <=> other
      major = version_hash[:major] <=> other.version_hash[:major]
      return major unless major == 0
      minor = version_hash[:minor] <=> other.version_hash[:minor]
      return minor unless minor == 0
      patch = version_hash[:patch] <=> other.version_hash[:patch]
      return patch unless patch == 0
      name = (version_hash[:name] || 'zzzz') <=> (other.version_hash[:name] || 'zzzz')
      return name unless name == 0
      build = version_hash[:build] <=> other.version_hash[:build]
      return build unless build == 0
      0
    end
  end

end

