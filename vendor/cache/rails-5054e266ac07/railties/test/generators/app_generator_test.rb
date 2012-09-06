require 'generators/generators_test_helper'
require 'rails/generators/rails/app/app_generator'
require 'generators/shared_generator_tests.rb'

DEFAULT_APP_FILES = %w(
  .gitignore
  Gemfile
  Rakefile
  config.ru
  app/assets/javascripts
  app/assets/stylesheets
  app/assets/images
  app/controllers
  app/helpers
  app/mailers
  app/models
  app/views/layouts
  config/environments
  config/initializers
  config/locales
  db
  doc
  lib
  lib/tasks
  lib/assets
  log
  script/rails
  test/fixtures
  test/functional
  test/integration
  test/performance
  test/unit
  vendor
  vendor/assets
  vendor/plugins
  tmp/cache
  tmp/cache/assets
)

class AppGeneratorTest < Rails::Generators::TestCase
  include GeneratorsTestHelper
  arguments [destination_root]

  # brings setup, teardown, and some tests
  include SharedGeneratorTests

  def default_files
    ::DEFAULT_APP_FILES
  end

  def test_assets
    run_generator
    assert_file "app/views/layouts/application.html.erb", /stylesheet_link_tag\s+"application"/
    assert_file "app/views/layouts/application.html.erb", /javascript_include_tag\s+"application"/
    assert_file "app/assets/stylesheets/application.css"
    assert_file "config/application.rb", /config\.assets\.enabled = true/
    assert_file "public/index.html", /url\("assets\/rails.png"\);/
  end

  def test_invalid_application_name_raises_an_error
    content = capture(:stderr){ run_generator [File.join(destination_root, "43-things")] }
    assert_equal "Invalid application name 43-things. Please give a name which does not start with numbers.\n", content
  end

  def test_invalid_application_name_is_fixed
    run_generator [File.join(destination_root, "things-43")]
    assert_file "things-43/config/environment.rb", /Things43::Application\.initialize!/
    assert_file "things-43/config/application.rb", /^module Things43$/
  end

  def test_application_new_exits_with_non_zero_code_on_invalid_application_name
    quietly { system 'rails new test' }
    assert_equal false, $?.success?
  end

  def test_application_new_exits_with_message_and_non_zero_code_when_generating_inside_existing_rails_directory
    app_root = File.join(destination_root, 'myfirstapp')
    run_generator [app_root]
    output = nil
    Dir.chdir(app_root) do
      output = `rails new mysecondapp`
    end
    assert_equal "Can't initialize a new Rails application within the directory of another, please change to a non-Rails directory first.\nType 'rails' for help.\n", output
    assert_equal false, $?.success?
  end

  def test_application_new_show_help_message_inside_existing_rails_directory
    app_root = File.join(destination_root, 'myfirstapp')
    run_generator [app_root]
    output = Dir.chdir(app_root) do
      `rails new --help`
    end
    assert_match /rails new APP_PATH \[options\]/, output
    assert_equal true, $?.success?
  end

  def test_application_name_is_detected_if_it_exists_and_app_folder_renamed
    app_root       = File.join(destination_root, "myapp")
    app_moved_root = File.join(destination_root, "myapp_moved")

    run_generator [app_root]

    Rails.application.config.root = app_moved_root
    Rails.application.class.stubs(:name).returns("Myapp")
    Rails.application.stubs(:is_a?).returns(Rails::Application)

    FileUtils.mv(app_root, app_moved_root)

    generator = Rails::Generators::AppGenerator.new ["rails"], { :with_dispatchers => true },
                                                               :destination_root => app_moved_root, :shell => @shell
    generator.send(:app_const)
    quietly { generator.send(:create_config_files) }
    assert_file "myapp_moved/config/environment.rb", /Myapp::Application\.initialize!/
    assert_file "myapp_moved/config/initializers/session_store.rb", /_myapp_session/
  end

  def test_rails_update_generates_correct_session_key
    app_root = File.join(destination_root, 'myapp')
    run_generator [app_root]

    Rails.application.config.root = app_root
    Rails.application.class.stubs(:name).returns("Myapp")
    Rails.application.stubs(:is_a?).returns(Rails::Application)

    generator = Rails::Generators::AppGenerator.new ["rails"], { :with_dispatchers => true }, :destination_root => app_root, :shell => @shell
    generator.send(:app_const)
    quietly { generator.send(:create_config_files) }
    assert_file "myapp/config/initializers/session_store.rb", /_myapp_session/
  end

  def test_application_names_are_not_singularized
    run_generator [File.join(destination_root, "hats")]
    assert_file "hats/config/environment.rb", /Hats::Application\.initialize!/
  end

  def test_gemfile_has_no_whitespace_errors
    run_generator
    absolute = File.expand_path("Gemfile", destination_root)
    File.open(absolute, 'r') do |f|
      f.each_line do |line|
        assert_no_match %r{/^[ \t]+$/}, line
      end
    end
  end

  def test_edge_gemfile_option
    generator([destination_root], :edge => true).expects(:bundle_command).with('install').once
    quietly { generator.invoke_all }
    assert_file 'Gemfile', %r{^\s+gem\s+["']sass-rails["'],\s+:git\s+=>\s+["']#{Regexp.escape("git://github.com/rails/sass-rails.git")}["'],\s+:branch\s+=>\s+["']3-2-stable["']$}
    assert_file 'Gemfile', %r{^\s+gem\s+["']coffee-rails["'],\s+:git\s+=>\s+["']#{Regexp.escape("git://github.com/rails/coffee-rails.git")}["'],\s+:branch\s+=>\s+["']3-2-stable["']$}
  end

  def test_config_database_is_added_by_default
    run_generator
    assert_file "config/database.yml", /sqlite3/
    unless defined?(JRUBY_VERSION)
      assert_file "Gemfile", /^gem\s+["']sqlite3["']$/
    else
      assert_file "Gemfile", /^gem\s+["']activerecord-jdbcsqlite3-adapter["']$/
    end
  end

  def test_config_another_database
    run_generator([destination_root, "-d", "mysql"])
    assert_file "config/database.yml", /mysql/
    unless defined?(JRUBY_VERSION)
      assert_file "Gemfile", /^gem\s+["']mysql2["']$/
    else
      assert_file "Gemfile", /^gem\s+["']activerecord-jdbcmysql-adapter["']$/
    end
  end

  def test_config_postgresql_database
    run_generator([destination_root, "-d", "postgresql"])
    assert_file "config/database.yml", /postgresql/
    unless defined?(JRUBY_VERSION)
      assert_file "Gemfile", /^gem\s+["']pg["']$/
    else
      assert_file "Gemfile", /^gem\s+["']activerecord-jdbcpostgresql-adapter["']$/
    end
  end

  def test_config_jdbcmysql_database
    run_generator([destination_root, "-d", "jdbcmysql"])
    assert_file "config/database.yml", /mysql/
    assert_file "Gemfile", /^gem\s+["']activerecord-jdbcmysql-adapter["']$/
    # TODO: When the JRuby guys merge jruby-openssl in
    # jruby this will be removed
    assert_file "Gemfile", /^gem\s+["']jruby-openssl["']$/ if defined?(JRUBY_VERSION)
  end

  def test_config_jdbcsqlite3_database
    run_generator([destination_root, "-d", "jdbcsqlite3"])
    assert_file "config/database.yml", /sqlite3/
    assert_file "Gemfile", /^gem\s+["']activerecord-jdbcsqlite3-adapter["']$/
  end

  def test_config_jdbcpostgresql_database
    run_generator([destination_root, "-d", "jdbcpostgresql"])
    assert_file "config/database.yml", /postgresql/
    assert_file "Gemfile", /^gem\s+["']activerecord-jdbcpostgresql-adapter["']$/
  end

  def test_config_jdbc_database
    run_generator([destination_root, "-d", "jdbc"])
    assert_file "config/database.yml", /jdbc/
    assert_file "config/database.yml", /mssql/
    assert_file "Gemfile", /^gem\s+["']activerecord-jdbc-adapter["']$/
  end

  def test_config_jdbc_database_when_no_option_given
    if defined?(JRUBY_VERSION)
      run_generator([destination_root])
      assert_file "config/database.yml", /sqlite3/
      assert_file "Gemfile", /^gem\s+["']activerecord-jdbcsqlite3-adapter["']$/
    end
  end

  def test_generator_if_skip_active_record_is_given
    run_generator [destination_root, "--skip-active-record"]
    assert_no_file "config/database.yml"
    assert_file "config/application.rb", /#\s+require\s+["']active_record\/railtie["']/
    assert_file "config/application.rb", /#\s+config\.active_record\.whitelist_attributes = true/
    assert_file "test/test_helper.rb" do |helper_content|
      assert_no_match(/fixtures :all/, helper_content)
    end
    assert_file "test/performance/browsing_test.rb"
  end

  def test_generator_if_skip_sprockets_is_given
    run_generator [destination_root, "--skip-sprockets"]
    assert_file "config/application.rb" do |content|
      assert_match(/#\s+require\s+["']sprockets\/railtie["']/, content)
      assert_no_match(/config\.assets\.enabled = true/, content)
    end
    assert_file "Gemfile" do |content|
      assert_no_match(/sass-rails/, content)
      assert_no_match(/coffee-rails/, content)
      assert_no_match(/uglifier/, content)
    end
    assert_file "config/environments/development.rb" do |content|
      assert_no_match(/config\.assets\.debug = true/, content)
    end
    assert_file "config/environments/production.rb" do |content|
      assert_no_match(/config\.assets\.digest = true/, content)
      assert_no_match(/config\.assets\.compress = true/, content)
    end
    assert_file "test/performance/browsing_test.rb"
  end

  def test_inclusion_of_javascript_runtime
    run_generator([destination_root])
    if defined?(JRUBY_VERSION)
      assert_file "Gemfile", /gem\s+["']therubyrhino["']$/
    else
      assert_file "Gemfile", /# gem\s+["']therubyracer["']+, :platforms => :ruby$/
    end
  end

  def test_creation_of_a_test_directory
    run_generator
    assert_file 'test'
  end

  def test_creation_of_vendor_assets_javascripts_directory
    run_generator
    assert_file "vendor/assets/javascripts"
  end

  def test_creation_of_vendor_assets_stylesheets_directory
    run_generator
    assert_file "vendor/assets/stylesheets"
  end

  def test_jquery_is_the_default_javascript_library
    run_generator
    assert_file "app/assets/javascripts/application.js" do |contents|
      assert_match %r{^//= require jquery}, contents
      assert_match %r{^//= require jquery_ujs}, contents
    end
    assert_file 'Gemfile' do |contents|
      assert_match(/^gem 'jquery-rails'/, contents)
    end
  end

  def test_other_javascript_libraries
    run_generator [destination_root, '-j', 'prototype']
    assert_file "app/assets/javascripts/application.js" do |contents|
      assert_match %r{^//= require prototype}, contents
      assert_match %r{^//= require prototype_ujs}, contents
    end
    assert_file 'Gemfile' do |contents|
      assert_match(/^gem 'prototype-rails'/, contents)
    end
  end

  def test_javascript_is_skipped_if_required
    run_generator [destination_root, "--skip-javascript"]
    assert_file "app/assets/javascripts/application.js" do |contents|
      assert_no_match %r{^//=\s+require\s}, contents
    end
  end

  def test_inclusion_of_ruby_debug
    run_generator
    assert_file "Gemfile" do |contents|
      assert_match(/gem 'ruby-debug'/, contents) if RUBY_VERSION < '1.9'
    end
  end

  def test_inclusion_of_debugger_if_ruby19
    run_generator
    assert_file "Gemfile" do |contents|
      assert_match(/gem 'debugger'/, contents) unless RUBY_VERSION < '1.9'
    end
  end

  def test_template_from_dir_pwd
    FileUtils.cd(Rails.root)
    assert_match(/It works from file!/, run_generator([destination_root, "-m", "lib/template.rb"]))
  end

  def test_usage_read_from_file
    File.expects(:read).returns("USAGE FROM FILE")
    assert_equal "USAGE FROM FILE", Rails::Generators::AppGenerator.desc
  end

  def test_default_usage
    Rails::Generators::AppGenerator.expects(:usage_path).returns(nil)
    assert_match(/Create rails files for app generator/, Rails::Generators::AppGenerator.desc)
  end

  def test_default_namespace
    assert_match "rails:app", Rails::Generators::AppGenerator.namespace
  end

  def test_file_is_added_for_backwards_compatibility
    action :file, 'lib/test_file.rb', 'heres test data'
    assert_file 'lib/test_file.rb', 'heres test data'
  end

  def test_test_unit_is_removed_from_frameworks_if_skip_test_unit_is_given
    run_generator [destination_root, "--skip-test-unit"]
    assert_file "config/application.rb", /#\s+require\s+["']rails\/test_unit\/railtie["']/
  end

  def test_no_active_record_or_test_unit_if_skips_given
    run_generator [destination_root, "--skip-test-unit", "--skip-active-record"]
    assert_file "config/application.rb", /#\s+require\s+["']rails\/test_unit\/railtie["']/
    assert_file "config/application.rb", /#\s+require\s+["']active_record\/railtie["']/
  end

  def test_new_hash_style
    run_generator [destination_root]
    assert_file "config/initializers/session_store.rb" do |file|
      if RUBY_VERSION < "1.9"
        assert_match(/config.session_store :cookie_store, :key => '_.+_session'/, file)
      else
        assert_match(/config.session_store :cookie_store, key: '_.+_session'/, file)
      end
    end
  end

  def test_force_old_style_hash
    run_generator [destination_root, "--old-style-hash"]
    assert_file "config/initializers/session_store.rb" do |file|
      assert_match(/config.session_store :cookie_store, :key => '_.+_session'/, file)
    end
  end

  def test_generated_environments_file_for_sanitizer
    run_generator [destination_root, "--skip-active-record"]
    %w(development test).each do |env|
      assert_file "config/environments/#{env}.rb" do |file|
        assert_no_match(/config.active_record.mass_assignment_sanitizer = :strict/, file)
      end
    end
  end

  def test_generated_environments_file_for_auto_explain
    run_generator [destination_root, "--skip-active-record"]
    %w(development production).each do |env|
      assert_file "config/environments/#{env}.rb" do |file|
        assert_no_match %r(auto_explain_threshold_in_seconds), file
      end
    end
  end

  def test_active_record_whitelist_attributes_is_present_application_config
    run_generator
    assert_file "config/application.rb", /config\.active_record\.whitelist_attributes = true/
  end

protected

  def action(*args, &block)
    silence(:stdout) { generator.send(*args, &block) }
  end

end

class CustomAppGeneratorTest < Rails::Generators::TestCase
  include GeneratorsTestHelper
  tests Rails::Generators::AppGenerator

  arguments [destination_root]
  include SharedCustomGeneratorTests

protected
  def default_files
    ::DEFAULT_APP_FILES
  end

  def builders_dir
    "app_builders"
  end

  def builder_class
    :AppBuilder
  end

  def action(*args, &block)
    silence(:stdout) { generator.send(*args, &block) }
  end
end
