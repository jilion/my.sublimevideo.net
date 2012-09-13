require 'abstract_unit'
require 'active_support/inflector'

require 'inflector_test_cases'
require 'constantize_test_cases'

class InflectorTest < Test::Unit::TestCase
  include InflectorTestCases
  include ConstantizeTestCases

  def test_pluralize_plurals
    assert_equal "plurals", ActiveSupport::Inflector.pluralize("plurals")
    assert_equal "Plurals", ActiveSupport::Inflector.pluralize("Plurals")
  end

  def test_pluralize_empty_string
    assert_equal "", ActiveSupport::Inflector.pluralize("")
  end

  ActiveSupport::Inflector.inflections.uncountable.each do |word|
    define_method "test_uncountability_of_#{word}" do
      assert_equal word, ActiveSupport::Inflector.singularize(word)
      assert_equal word, ActiveSupport::Inflector.pluralize(word)
      assert_equal ActiveSupport::Inflector.pluralize(word), ActiveSupport::Inflector.singularize(word)
    end
  end

  def test_uncountable_word_is_not_greedy
    uncountable_word = "ors"
    countable_word = "sponsor"

    cached_uncountables = ActiveSupport::Inflector.inflections.uncountables

    ActiveSupport::Inflector.inflections.uncountable << uncountable_word

    assert_equal uncountable_word, ActiveSupport::Inflector.singularize(uncountable_word)
    assert_equal uncountable_word, ActiveSupport::Inflector.pluralize(uncountable_word)
    assert_equal ActiveSupport::Inflector.pluralize(uncountable_word), ActiveSupport::Inflector.singularize(uncountable_word)

    assert_equal "sponsor", ActiveSupport::Inflector.singularize(countable_word)
    assert_equal "sponsors", ActiveSupport::Inflector.pluralize(countable_word)
    assert_equal "sponsor", ActiveSupport::Inflector.singularize(ActiveSupport::Inflector.pluralize(countable_word))

  ensure
    ActiveSupport::Inflector.inflections.instance_variable_set :@uncountables, cached_uncountables
  end

  SingularToPlural.each do |singular, plural|
    define_method "test_pluralize_singular_#{singular}" do
      assert_equal(plural, ActiveSupport::Inflector.pluralize(singular))
      assert_equal(plural.capitalize, ActiveSupport::Inflector.pluralize(singular.capitalize))
    end
  end

  SingularToPlural.each do |singular, plural|
    define_method "test_singularize_plural_#{plural}" do
      assert_equal(singular, ActiveSupport::Inflector.singularize(plural))
      assert_equal(singular.capitalize, ActiveSupport::Inflector.singularize(plural.capitalize))
    end
  end

  SingularToPlural.each do |singular, plural|
    define_method "test_pluralize_plural_#{plural}" do
      assert_equal(plural, ActiveSupport::Inflector.pluralize(plural))
      assert_equal(plural.capitalize, ActiveSupport::Inflector.pluralize(plural.capitalize))
    end
  end

  def test_overwrite_previous_inflectors
    assert_equal("series", ActiveSupport::Inflector.singularize("series"))
    ActiveSupport::Inflector.inflections.singular "series", "serie"
    assert_equal("serie", ActiveSupport::Inflector.singularize("series"))
    ActiveSupport::Inflector.inflections.uncountable "series" # Return to normal
  end

  MixtureToTitleCase.each do |before, titleized|
    define_method "test_titleize_#{before}" do
      assert_equal(titleized, ActiveSupport::Inflector.titleize(before))
    end
  end

  def test_camelize
    CamelToUnderscore.each do |camel, underscore|
      assert_equal(camel, ActiveSupport::Inflector.camelize(underscore))
    end
  end

  def test_camelize_with_lower_downcases_the_first_letter
    assert_equal('capital', ActiveSupport::Inflector.camelize('Capital', false))
  end

  def test_camelize_with_underscores
    assert_equal("CamelCase", ActiveSupport::Inflector.camelize('Camel_Case'))
  end

  def test_acronyms
    ActiveSupport::Inflector.inflections do |inflect|
      inflect.acronym("API")
      inflect.acronym("HTML")
      inflect.acronym("HTTP")
      inflect.acronym("RESTful")
      inflect.acronym("W3C")
      inflect.acronym("PhD")
      inflect.acronym("RoR")
      inflect.acronym("SSL")
    end

    #  camelize             underscore            humanize              titleize
    [
      ["API",               "api",                "API",                "API"],
      ["APIController",     "api_controller",     "API controller",     "API Controller"],
      ["Nokogiri::HTML",    "nokogiri/html",      "Nokogiri/HTML",      "Nokogiri/HTML"],
      ["HTTPAPI",           "http_api",           "HTTP API",           "HTTP API"],
      ["HTTP::Get",         "http/get",           "HTTP/get",           "HTTP/Get"],
      ["SSLError",          "ssl_error",          "SSL error",          "SSL Error"],
      ["RESTful",           "restful",            "RESTful",            "RESTful"],
      ["RESTfulController", "restful_controller", "RESTful controller", "RESTful Controller"],
      ["IHeartW3C",         "i_heart_w3c",        "I heart W3C",        "I Heart W3C"],
      ["PhDRequired",       "phd_required",       "PhD required",       "PhD Required"],
      ["IRoRU",             "i_ror_u",            "I RoR u",            "I RoR U"],
      ["RESTfulHTTPAPI",    "restful_http_api",   "RESTful HTTP API",   "RESTful HTTP API"],

      # misdirection
      ["Capistrano",        "capistrano",         "Capistrano",       "Capistrano"],
      ["CapiController",    "capi_controller",    "Capi controller",  "Capi Controller"],
      ["HttpsApis",         "https_apis",         "Https apis",       "Https Apis"],
      ["Html5",             "html5",              "Html5",            "Html5"],
      ["Restfully",         "restfully",          "Restfully",        "Restfully"],
      ["RoRails",           "ro_rails",           "Ro rails",         "Ro Rails"]
    ].each do |camel, under, human, title|
      assert_equal(camel, ActiveSupport::Inflector.camelize(under))
      assert_equal(camel, ActiveSupport::Inflector.camelize(camel))
      assert_equal(under, ActiveSupport::Inflector.underscore(under))
      assert_equal(under, ActiveSupport::Inflector.underscore(camel))
      assert_equal(title, ActiveSupport::Inflector.titleize(under))
      assert_equal(title, ActiveSupport::Inflector.titleize(camel))
      assert_equal(human, ActiveSupport::Inflector.humanize(under))
    end
  end

  def test_acronym_override
    ActiveSupport::Inflector.inflections do |inflect|
      inflect.acronym("API")
      inflect.acronym("LegacyApi")
    end

    assert_equal("LegacyApi", ActiveSupport::Inflector.camelize("legacyapi"))
    assert_equal("LegacyAPI", ActiveSupport::Inflector.camelize("legacy_api"))
    assert_equal("SomeLegacyApi", ActiveSupport::Inflector.camelize("some_legacyapi"))
    assert_equal("Nonlegacyapi", ActiveSupport::Inflector.camelize("nonlegacyapi"))
  end

  def test_acronyms_camelize_lower
    ActiveSupport::Inflector.inflections do |inflect|
      inflect.acronym("API")
      inflect.acronym("HTML")
    end

    assert_equal("htmlAPI", ActiveSupport::Inflector.camelize("html_api", false))
    assert_equal("htmlAPI", ActiveSupport::Inflector.camelize("htmlAPI", false))
    assert_equal("htmlAPI", ActiveSupport::Inflector.camelize("HTMLAPI", false))
  end

  def test_underscore_acronym_sequence
    ActiveSupport::Inflector.inflections do |inflect|
      inflect.acronym("API")
      inflect.acronym("HTML5")
      inflect.acronym("HTML")
    end

    assert_equal("html5_html_api", ActiveSupport::Inflector.underscore("HTML5HTMLAPI"))
  end

  def test_underscore
    CamelToUnderscore.each do |camel, underscore|
      assert_equal(underscore, ActiveSupport::Inflector.underscore(camel))
    end
    CamelToUnderscoreWithoutReverse.each do |camel, underscore|
      assert_equal(underscore, ActiveSupport::Inflector.underscore(camel))
    end
  end

  def test_camelize_with_module
    CamelWithModuleToUnderscoreWithSlash.each do |camel, underscore|
      assert_equal(camel, ActiveSupport::Inflector.camelize(underscore))
    end
  end

  def test_underscore_with_slashes
    CamelWithModuleToUnderscoreWithSlash.each do |camel, underscore|
      assert_equal(underscore, ActiveSupport::Inflector.underscore(camel))
    end
  end

  def test_demodulize
    assert_equal "Account", ActiveSupport::Inflector.demodulize("MyApplication::Billing::Account")
    assert_equal "Account", ActiveSupport::Inflector.demodulize("Account")
    assert_equal "", ActiveSupport::Inflector.demodulize("")
  end

  def test_deconstantize
    assert_equal "MyApplication::Billing", ActiveSupport::Inflector.deconstantize("MyApplication::Billing::Account")
    assert_equal "::MyApplication::Billing", ActiveSupport::Inflector.deconstantize("::MyApplication::Billing::Account")

    assert_equal "MyApplication", ActiveSupport::Inflector.deconstantize("MyApplication::Billing")
    assert_equal "::MyApplication", ActiveSupport::Inflector.deconstantize("::MyApplication::Billing")

    assert_equal "", ActiveSupport::Inflector.deconstantize("Account")
    assert_equal "", ActiveSupport::Inflector.deconstantize("::Account")
    assert_equal "", ActiveSupport::Inflector.deconstantize("")
  end

  def test_foreign_key
    ClassNameToForeignKeyWithUnderscore.each do |klass, foreign_key|
      assert_equal(foreign_key, ActiveSupport::Inflector.foreign_key(klass))
    end

    ClassNameToForeignKeyWithoutUnderscore.each do |klass, foreign_key|
      assert_equal(foreign_key, ActiveSupport::Inflector.foreign_key(klass, false))
    end
  end

  def test_tableize
    ClassNameToTableName.each do |class_name, table_name|
      assert_equal(table_name, ActiveSupport::Inflector.tableize(class_name))
    end
  end

  def test_parameterize
    StringToParameterized.each do |some_string, parameterized_string|
      assert_equal(parameterized_string, ActiveSupport::Inflector.parameterize(some_string))
    end
  end

  def test_parameterize_and_normalize
    StringToParameterizedAndNormalized.each do |some_string, parameterized_string|
      assert_equal(parameterized_string, ActiveSupport::Inflector.parameterize(some_string))
    end
  end

  def test_parameterize_with_custom_separator
    StringToParameterizeWithUnderscore.each do |some_string, parameterized_string|
      assert_equal(parameterized_string, ActiveSupport::Inflector.parameterize(some_string, '_'))
    end
  end

  def test_parameterize_with_multi_character_separator
    StringToParameterized.each do |some_string, parameterized_string|
      assert_equal(parameterized_string.gsub('-', '__sep__'), ActiveSupport::Inflector.parameterize(some_string, '__sep__'))
    end
  end

  def test_classify
    ClassNameToTableName.each do |class_name, table_name|
      assert_equal(class_name, ActiveSupport::Inflector.classify(table_name))
      assert_equal(class_name, ActiveSupport::Inflector.classify("table_prefix." + table_name))
    end
  end

  def test_classify_with_symbol
    assert_nothing_raised do
      assert_equal 'FooBar', ActiveSupport::Inflector.classify(:foo_bars)
    end
  end

  def test_classify_with_leading_schema_name
    assert_equal 'FooBar', ActiveSupport::Inflector.classify('schema.foo_bar')
  end

  def test_humanize
    UnderscoreToHuman.each do |underscore, human|
      assert_equal(human, ActiveSupport::Inflector.humanize(underscore))
    end
  end

  def test_humanize_by_rule
    ActiveSupport::Inflector.inflections do |inflect|
      inflect.human(/_cnt$/i, '\1_count')
      inflect.human(/^prefx_/i, '\1')
    end
    assert_equal("Jargon count", ActiveSupport::Inflector.humanize("jargon_cnt"))
    assert_equal("Request", ActiveSupport::Inflector.humanize("prefx_request"))
  end

  def test_humanize_by_string
    ActiveSupport::Inflector.inflections do |inflect|
      inflect.human("col_rpted_bugs", "Reported bugs")
    end
    assert_equal("Reported bugs", ActiveSupport::Inflector.humanize("col_rpted_bugs"))
    assert_equal("Col rpted bugs", ActiveSupport::Inflector.humanize("COL_rpted_bugs"))
  end

  def test_constantize
    run_constantize_tests_on do |string|
      ActiveSupport::Inflector.constantize(string)
    end
  end
  
  def test_safe_constantize
    run_safe_constantize_tests_on do |string|
      ActiveSupport::Inflector.safe_constantize(string)
    end
  end

  def test_ordinal
    OrdinalNumbers.each do |number, ordinalized|
      assert_equal(ordinalized, ActiveSupport::Inflector.ordinalize(number))
    end
  end

  def test_dasherize
    UnderscoresToDashes.each do |underscored, dasherized|
      assert_equal(dasherized, ActiveSupport::Inflector.dasherize(underscored))
    end
  end

  def test_underscore_as_reverse_of_dasherize
    UnderscoresToDashes.each do |underscored, dasherized|
      assert_equal(underscored, ActiveSupport::Inflector.underscore(ActiveSupport::Inflector.dasherize(underscored)))
    end
  end

  def test_underscore_to_lower_camel
    UnderscoreToLowerCamel.each do |underscored, lower_camel|
      assert_equal(lower_camel, ActiveSupport::Inflector.camelize(underscored, false))
    end
  end

  def test_symbol_to_lower_camel
    SymbolToLowerCamel.each do |symbol, lower_camel|
      assert_equal(lower_camel, ActiveSupport::Inflector.camelize(symbol, false))
    end
  end

  %w{plurals singulars uncountables humans}.each do |inflection_type|
    class_eval <<-RUBY, __FILE__, __LINE__ + 1
      def test_clear_#{inflection_type}
        cached_values = ActiveSupport::Inflector.inflections.#{inflection_type}
        ActiveSupport::Inflector.inflections.clear :#{inflection_type}
        assert ActiveSupport::Inflector.inflections.#{inflection_type}.empty?, \"#{inflection_type} inflections should be empty after clear :#{inflection_type}\"
        ActiveSupport::Inflector.inflections.instance_variable_set :@#{inflection_type}, cached_values
      end
    RUBY
  end

  def test_clear_all
    cached_values = ActiveSupport::Inflector.inflections.plurals.dup, ActiveSupport::Inflector.inflections.singulars.dup, ActiveSupport::Inflector.inflections.uncountables.dup, ActiveSupport::Inflector.inflections.humans.dup
    ActiveSupport::Inflector.inflections do |inflect|
      # ensure any data is present
      inflect.plural(/(quiz)$/i, '\1zes')
      inflect.singular(/(database)s$/i, '\1')
      inflect.uncountable('series')
      inflect.human("col_rpted_bugs", "Reported bugs")

      inflect.clear :all

      assert inflect.plurals.empty?
      assert inflect.singulars.empty?
      assert inflect.uncountables.empty?
      assert inflect.humans.empty?
    end
    ActiveSupport::Inflector.inflections.instance_variable_set :@plurals, cached_values[0]
    ActiveSupport::Inflector.inflections.instance_variable_set :@singulars, cached_values[1]
    ActiveSupport::Inflector.inflections.instance_variable_set :@uncountables, cached_values[2]
    ActiveSupport::Inflector.inflections.instance_variable_set :@humans, cached_values[3]
  end

  def test_clear_with_default
    cached_values = ActiveSupport::Inflector.inflections.plurals.dup, ActiveSupport::Inflector.inflections.singulars.dup, ActiveSupport::Inflector.inflections.uncountables.dup, ActiveSupport::Inflector.inflections.humans.dup
    ActiveSupport::Inflector.inflections do |inflect|
      # ensure any data is present
      inflect.plural(/(quiz)$/i, '\1zes')
      inflect.singular(/(database)s$/i, '\1')
      inflect.uncountable('series')
      inflect.human("col_rpted_bugs", "Reported bugs")

      inflect.clear

      assert inflect.plurals.empty?
      assert inflect.singulars.empty?
      assert inflect.uncountables.empty?
      assert inflect.humans.empty?
    end
    ActiveSupport::Inflector.inflections.instance_variable_set :@plurals, cached_values[0]
    ActiveSupport::Inflector.inflections.instance_variable_set :@singulars, cached_values[1]
    ActiveSupport::Inflector.inflections.instance_variable_set :@uncountables, cached_values[2]
    ActiveSupport::Inflector.inflections.instance_variable_set :@humans, cached_values[3]
  end

  Irregularities.each do |irregularity|
    singular, plural = *irregularity
    ActiveSupport::Inflector.inflections do |inflect|
      define_method("test_irregularity_between_#{singular}_and_#{plural}") do
        inflect.irregular(singular, plural)
        assert_equal singular, ActiveSupport::Inflector.singularize(plural)
        assert_equal plural, ActiveSupport::Inflector.pluralize(singular)
      end
    end
  end

  Irregularities.each do |irregularity|
    singular, plural = *irregularity
    ActiveSupport::Inflector.inflections do |inflect|
      define_method("test_pluralize_of_irregularity_#{plural}_should_be_the_same") do
        inflect.irregular(singular, plural)
        assert_equal plural, ActiveSupport::Inflector.pluralize(plural)
      end
    end
  end

  [ :all, [] ].each do |scope|
    ActiveSupport::Inflector.inflections do |inflect|
      define_method("test_clear_inflections_with_#{scope.kind_of?(Array) ? "no_arguments" : scope}") do
        # save all the inflections
        singulars, plurals, uncountables = inflect.singulars, inflect.plurals, inflect.uncountables

        # clear all the inflections
        inflect.clear(*scope)

        assert_equal [], inflect.singulars
        assert_equal [], inflect.plurals
        assert_equal [], inflect.uncountables

        # restore all the inflections
        singulars.reverse.each { |singular| inflect.singular(*singular) }
        plurals.reverse.each   { |plural|   inflect.plural(*plural) }
        inflect.uncountable(uncountables)

        assert_equal singulars, inflect.singulars
        assert_equal plurals, inflect.plurals
        assert_equal uncountables, inflect.uncountables
      end
    end
  end

  { :singulars => :singular, :plurals => :plural, :uncountables => :uncountable, :humans => :human }.each do |scope, method|
    ActiveSupport::Inflector.inflections do |inflect|
      define_method("test_clear_inflections_with_#{scope}") do
        # save the inflections
        values = inflect.send(scope)

        # clear the inflections
        inflect.clear(scope)

        assert_equal [], inflect.send(scope)

        # restore the inflections
        if scope == :uncountables
          inflect.send(method, values)
        else
          values.reverse.each { |value| inflect.send(method, *value) }
        end

        assert_equal values, inflect.send(scope)
      end
    end
  end
end
