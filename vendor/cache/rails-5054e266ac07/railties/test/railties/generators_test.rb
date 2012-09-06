RAILS_ISOLATED_ENGINE = true
require "isolation/abstract_unit"

require 'generators/generators_test_helper'
require "rails/generators/test_case"

module RailtiesTests
  class GeneratorTest < Rails::Generators::TestCase
    include ActiveSupport::Testing::Isolation

    TMP_PATH = File.expand_path(File.join(File.dirname(__FILE__), *%w[.. .. tmp]))
    self.destination_root = File.join(TMP_PATH, "foo_bar")

    def tmp_path(*args)
      File.join(TMP_PATH, *args)
    end

    def engine_path
      tmp_path('foo_bar')
    end

    def bundled_rails(cmd)
      `bundle exec rails #{cmd}`
    end

    def rails(cmd)
      environment = File.expand_path('../../../../load_paths', __FILE__)
      if File.exist?("#{environment}.rb")
        require_environment = "-r #{environment}"
      end
      `#{Gem.ruby} #{require_environment} #{RAILS_FRAMEWORK_ROOT}/railties/bin/rails #{cmd}`
    end

    def build_engine(is_mountable=false)
      FileUtils.rm_rf(engine_path)
      FileUtils.mkdir_p(engine_path)

      mountable = is_mountable ? "--mountable" : ""

      rails("plugin new #{engine_path} --full #{mountable}")

      Dir.chdir(engine_path) do
        File.open("Gemfile", "w") do |f|
          f.write <<-GEMFILE.gsub(/^ {12}/, '')
            source "http://rubygems.org"

            gem 'rails', :path => '#{RAILS_FRAMEWORK_ROOT}'
            gem 'sqlite3'

            if RUBY_VERSION < '1.9'
              gem "ruby-debug", ">= 0.10.3"
            end
          GEMFILE
        end
      end
    end

    def build_mountable_engine
      build_engine(true)
    end

    def test_controllers_are_correctly_namespaced_when_engine_is_mountable
      build_mountable_engine
      Dir.chdir(engine_path) do
        bundled_rails("g controller topics")
        assert_file "app/controllers/foo_bar/topics_controller.rb", /module FooBar\n  class TopicsController/
        assert_no_file "app/controllers/topics_controller.rb"
      end
    end

    def test_models_are_correctly_namespaced_when_engine_is_mountable
      build_mountable_engine
      Dir.chdir(engine_path) do
        bundled_rails("g model topic")
        assert_file "app/models/foo_bar/topic.rb", /module FooBar\n  class Topic/
        assert_no_file "app/models/topic.rb"
      end
    end

    def test_helpers_are_correctly_namespaced_when_engine_is_mountable
      build_mountable_engine
      Dir.chdir(engine_path) do
        bundled_rails("g helper topics")
        assert_file "app/helpers/foo_bar/topics_helper.rb", /module FooBar\n  module TopicsHelper/
        assert_no_file "app/helpers/topics_helper.rb"
      end
    end

    def test_controllers_are_not_namespaced_when_engine_is_not_mountable
      build_engine
      Dir.chdir(engine_path) do
        bundled_rails("g controller topics")
        assert_file "app/controllers/topics_controller.rb", /class TopicsController/
        assert_no_file "app/controllers/foo_bar/topics_controller.rb"
      end
    end

    def test_models_are_not_namespaced_when_engine_is_not_mountable
      build_engine
      Dir.chdir(engine_path) do
        bundled_rails("g model topic")
        assert_file "app/models/topic.rb", /class Topic/
        assert_no_file "app/models/foo_bar/topic.rb"
      end
    end

    def test_helpers_are_not_namespaced_when_engine_is_not_mountable
      build_engine
      Dir.chdir(engine_path) do
        bundled_rails("g helper topics")
        assert_file "app/helpers/topics_helper.rb", /module TopicsHelper/
        assert_no_file "app/helpers/foo_bar/topics_helper.rb"
      end
    end
  end
end
