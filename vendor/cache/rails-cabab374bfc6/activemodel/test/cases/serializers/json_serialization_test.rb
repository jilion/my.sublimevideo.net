require 'cases/helper'
require 'models/contact'
require 'models/automobile'
require 'active_support/core_ext/object/instance_variables'

class Contact
  extend ActiveModel::Naming
  include ActiveModel::Serializers::JSON
  include ActiveModel::Validations

  def attributes=(hash)
    hash.each do |k, v|
      instance_variable_set("@#{k}", v)
    end
  end

  remove_method :attributes if method_defined?(:attributes)

  def attributes
    instance_values
  end
end

class JsonSerializationTest < ActiveModel::TestCase
  def setup
    @contact = Contact.new
    @contact.name = 'Konata Izumi'
    @contact.age = 16
    @contact.created_at = Time.utc(2006, 8, 1)
    @contact.awesome = true
    @contact.preferences = { 'shows' => 'anime' }
  end

  test "should include root in json" do
    json = @contact.to_json

    assert_match %r{^\{"contact":\{}, json
    assert_match %r{"name":"Konata Izumi"}, json
    assert_match %r{"age":16}, json
    assert json.include?(%("created_at":#{ActiveSupport::JSON.encode(Time.utc(2006, 8, 1))}))
    assert_match %r{"awesome":true}, json
    assert_match %r{"preferences":\{"shows":"anime"\}}, json
  end

  test "should not include root in json (class method)" do
    begin
      Contact.include_root_in_json = false
      json = @contact.to_json

      assert_no_match %r{^\{"contact":\{}, json
      assert_match %r{"name":"Konata Izumi"}, json
      assert_match %r{"age":16}, json
      assert json.include?(%("created_at":#{ActiveSupport::JSON.encode(Time.utc(2006, 8, 1))}))
      assert_match %r{"awesome":true}, json
      assert_match %r{"preferences":\{"shows":"anime"\}}, json
    ensure
      Contact.include_root_in_json = true
    end
  end

  test "should include root in json (option) even if the default is set to false" do
    begin
      Contact.include_root_in_json = false
      json = @contact.to_json(:root => true)
      assert_match %r{^\{"contact":\{}, json
    ensure
      Contact.include_root_in_json = true
    end
  end

  test "should not include root in json (option)" do

    json = @contact.to_json(:root => false)

    assert_no_match %r{^\{"contact":\{}, json
  end

  test "should include custom root in json" do
    json = @contact.to_json(:root => 'json_contact')

    assert_match %r{^\{"json_contact":\{}, json
    assert_match %r{"name":"Konata Izumi"}, json
    assert_match %r{"age":16}, json
    assert json.include?(%("created_at":#{ActiveSupport::JSON.encode(Time.utc(2006, 8, 1))}))
    assert_match %r{"awesome":true}, json
    assert_match %r{"preferences":\{"shows":"anime"\}}, json
  end

  test "should encode all encodable attributes" do
    json = @contact.to_json

    assert_match %r{"name":"Konata Izumi"}, json
    assert_match %r{"age":16}, json
    assert json.include?(%("created_at":#{ActiveSupport::JSON.encode(Time.utc(2006, 8, 1))}))
    assert_match %r{"awesome":true}, json
    assert_match %r{"preferences":\{"shows":"anime"\}}, json
  end

  test "should allow attribute filtering with only" do
    json = @contact.to_json(:only => [:name, :age])

    assert_match %r{"name":"Konata Izumi"}, json
    assert_match %r{"age":16}, json
    assert_no_match %r{"awesome":true}, json
    assert !json.include?(%("created_at":#{ActiveSupport::JSON.encode(Time.utc(2006, 8, 1))}))
    assert_no_match %r{"preferences":\{"shows":"anime"\}}, json
  end

  test "should allow attribute filtering with except" do
    json = @contact.to_json(:except => [:name, :age])

    assert_no_match %r{"name":"Konata Izumi"}, json
    assert_no_match %r{"age":16}, json
    assert_match %r{"awesome":true}, json
    assert json.include?(%("created_at":#{ActiveSupport::JSON.encode(Time.utc(2006, 8, 1))}))
    assert_match %r{"preferences":\{"shows":"anime"\}}, json
  end

  test "methods are called on object" do
    # Define methods on fixture.
    def @contact.label; "Has cheezburger"; end
    def @contact.favorite_quote; "Constraints are liberating"; end

    # Single method.
    assert_match %r{"label":"Has cheezburger"}, @contact.to_json(:only => :name, :methods => :label)

    # Both methods.
    methods_json = @contact.to_json(:only => :name, :methods => [:label, :favorite_quote])
    assert_match %r{"label":"Has cheezburger"}, methods_json
    assert_match %r{"favorite_quote":"Constraints are liberating"}, methods_json
  end

  test "should return OrderedHash for errors" do
    contact = Contact.new
    contact.errors.add :name, "can't be blank"
    contact.errors.add :name, "is too short (minimum is 2 characters)"
    contact.errors.add :age, "must be 16 or over"

    hash = ActiveSupport::OrderedHash.new
    hash[:name] = ["can't be blank", "is too short (minimum is 2 characters)"]
    hash[:age]  = ["must be 16 or over"]
    assert_equal hash.to_json, contact.errors.to_json
  end

  test "serializable_hash should not modify options passed in argument" do
    options = { :except => :name }
    @contact.serializable_hash(options)

    assert_nil options[:only]
    assert_equal :name, options[:except]
  end

  test "as_json should return a hash" do
    json = @contact.as_json

    assert_kind_of Hash, json
    assert_kind_of Hash, json['contact']
    %w(name age created_at awesome preferences).each do |field|
      assert_equal @contact.send(field), json['contact'][field]
    end
  end

  test "from_json should set the object's attributes" do
    json = @contact.to_json
    result = Contact.new.from_json(json)

    assert_equal result.name, @contact.name
    assert_equal result.age, @contact.age
    assert_equal Time.parse(result.created_at), @contact.created_at
    assert_equal result.awesome, @contact.awesome
    assert_equal result.preferences, @contact.preferences
  end

  test "from_json should work without a root (method parameter)" do
    json = @contact.to_json(:root => false)
    result = Contact.new.from_json(json, false)

    assert_equal result.name, @contact.name
    assert_equal result.age, @contact.age
    assert_equal Time.parse(result.created_at), @contact.created_at
    assert_equal result.awesome, @contact.awesome
    assert_equal result.preferences, @contact.preferences
  end

  test "from_json should work without a root (class attribute)" do
    begin
      Contact.include_root_in_json = false
      json = @contact.to_json
      result = Contact.new.from_json(json)

      assert_equal result.name, @contact.name
      assert_equal result.age, @contact.age
      assert_equal Time.parse(result.created_at), @contact.created_at
      assert_equal result.awesome, @contact.awesome
      assert_equal result.preferences, @contact.preferences
    ensure
      Contact.include_root_in_json = true
    end
  end

  test "custom as_json should be honored when generating json" do
    def @contact.as_json(options); { :name => name, :created_at => created_at }; end
    json = @contact.to_json

    assert_match %r{"name":"Konata Izumi"}, json
    assert_match %r{"created_at":#{ActiveSupport::JSON.encode(Time.utc(2006, 8, 1))}}, json
    assert_no_match %r{"awesome":}, json
    assert_no_match %r{"preferences":}, json
  end

  test "custom as_json options should be extendible" do
    def @contact.as_json(options = {}); super(options.merge(:only => [:name])); end
    json = @contact.to_json

    assert_match %r{"name":"Konata Izumi"}, json
    assert_no_match %r{"created_at":#{ActiveSupport::JSON.encode(Time.utc(2006, 8, 1))}}, json
    assert_no_match %r{"awesome":}, json
    assert_no_match %r{"preferences":}, json
  end

end
