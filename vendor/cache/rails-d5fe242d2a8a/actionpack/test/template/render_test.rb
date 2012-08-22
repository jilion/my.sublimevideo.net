# encoding: utf-8
require 'abstract_unit'
require 'controller/fake_models'

class TestController < ActionController::Base
end

module RenderTestCases
  def setup_view(paths)
    @assigns = { :secret => 'in the sauce' }
    @view = ActionView::Base.new(paths, @assigns)
    @controller_view = TestController.new.view_context

    # Reload and register danish language for testing
    I18n.reload!
    I18n.backend.store_translations 'da', {}
    I18n.backend.store_translations 'pt-BR', {}

    # Ensure original are still the same since we are reindexing view paths
    assert_equal ORIGINAL_LOCALES, I18n.available_locales.map {|l| l.to_s }.sort
  end

  def test_render_without_options
    e = assert_raises(ArgumentError) { @view.render() }
    assert_match "You invoked render but did not give any of :partial, :template, :inline, :file or :text option.", e.message
  end

  def test_render_file
    assert_equal "Hello world!", @view.render(:file => "test/hello_world")
  end

  def test_render_file_not_using_full_path
    assert_equal "Hello world!", @view.render(:file => "test/hello_world")
  end

  def test_render_file_without_specific_extension
    assert_equal "Hello world!", @view.render(:file => "test/hello_world")
  end

  # Test if :formats, :locale etc. options are passed correctly to the resolvers.
  def test_render_file_with_format
    assert_match "<h1>No Comment</h1>", @view.render(:file => "comments/empty", :formats => [:html])
    assert_match "<error>No Comment</error>", @view.render(:file => "comments/empty", :formats => [:xml])
    assert_match "<error>No Comment</error>", @view.render(:file => "comments/empty", :formats => :xml)
  end

  def test_render_template_with_format
    assert_match "<h1>No Comment</h1>", @view.render(:template => "comments/empty", :formats => [:html])
    assert_match "<error>No Comment</error>", @view.render(:template => "comments/empty", :formats => [:xml])
  end

  def test_render_partial_implicitly_use_format_of_the_rendered_template
    @view.lookup_context.formats = [:json]
    assert_equal "Hello world", @view.render(:template => "test/one", :formats => [:html])
  end

  def test_render_template_with_a_missing_partial_of_another_format
    @view.lookup_context.formats = [:html]
    assert_raise ActionView::Template::Error, "Missing partial /missing with {:locale=>[:en], :formats=>[:json], :handlers=>[:erb, :builder]}" do
      @view.render(:template => "with_format", :formats => [:json])
    end
  end

  def test_render_file_with_locale
    assert_equal "<h1>Kein Kommentar</h1>", @view.render(:file => "comments/empty", :locale => [:de])
    assert_equal "<h1>Kein Kommentar</h1>", @view.render(:file => "comments/empty", :locale => :de)
  end

  def test_render_template_with_locale
    assert_equal "<h1>Kein Kommentar</h1>", @view.render(:template => "comments/empty", :locale => [:de])
  end

  def test_render_file_with_handlers
    assert_equal "<h1>No Comment</h1>\n", @view.render(:file => "comments/empty", :handlers => [:builder])
    assert_equal "<h1>No Comment</h1>\n", @view.render(:file => "comments/empty", :handlers => :builder)
  end

  def test_render_template_with_handlers
    assert_equal "<h1>No Comment</h1>\n", @view.render(:template => "comments/empty", :handlers => [:builder])
  end

  def test_render_file_with_localization_on_context_level
    old_locale, @view.locale = @view.locale, :da
    assert_equal "Hey verden", @view.render(:file => "test/hello_world")
  ensure
    @view.locale = old_locale
  end

  def test_render_file_with_dashed_locale
    old_locale, @view.locale = @view.locale, :"pt-BR"
    assert_equal "Ola mundo", @view.render(:file => "test/hello_world")
  ensure
    @view.locale = old_locale
  end

  def test_render_file_at_top_level
    assert_equal 'Elastica', @view.render(:file => '/shared')
  end

  def test_render_file_with_full_path
    template_path = File.join(File.dirname(__FILE__), '../fixtures/test/hello_world')
    assert_equal "Hello world!", @view.render(:file => template_path)
  end

  def test_render_file_with_instance_variables
    assert_equal "The secret is in the sauce\n", @view.render(:file => "test/render_file_with_ivar")
  end

  def test_render_file_with_locals
    locals = { :secret => 'in the sauce' }
    assert_equal "The secret is in the sauce\n", @view.render(:file => "test/render_file_with_locals", :locals => locals)
  end

  def test_render_file_not_using_full_path_with_dot_in_path
    assert_equal "The secret is in the sauce\n", @view.render(:file => "test/dot.directory/render_file_with_ivar")
  end

  def test_render_partial_from_default
    assert_equal "only partial", @view.render("test/partial_only")
  end

  def test_render_partial
    assert_equal "only partial", @view.render(:partial => "test/partial_only")
  end

  def test_render_partial_with_format
    assert_equal 'partial html', @view.render(:partial => 'test/partial')
  end

  def test_render_partial_with_selected_format
    assert_equal 'partial html', @view.render(:partial => 'test/partial', :formats => :html)
    assert_equal 'partial js', @view.render(:partial => 'test/partial', :formats => [:js])
  end

  def test_render_partial_at_top_level
    # file fixtures/_top_level_partial_only (not fixtures/test)
    assert_equal 'top level partial', @view.render(:partial => '/top_level_partial_only')
  end

  def test_render_partial_with_format_at_top_level
    # file fixtures/_top_level_partial.html (not fixtures/test, with format extension)
    assert_equal 'top level partial html', @view.render(:partial => '/top_level_partial')
  end

  def test_render_partial_with_locals
    assert_equal "5", @view.render(:partial => "test/counter", :locals => { :counter_counter => 5 })
  end

  def test_render_partial_with_locals_from_default
    assert_equal "only partial", @view.render("test/partial_only", :counter_counter => 5)
  end

  def test_render_partial_with_invalid_name
    e = assert_raises(ArgumentError) { @view.render(:partial => "test/200") }
    assert_equal "The partial name (test/200) is not a valid Ruby identifier; " +
      "make sure your partial name starts with a letter or underscore, " +
      "and is followed by any combinations of letters, numbers, or underscores.", e.message
  end

  def test_render_partial_with_missing_filename
    e = assert_raises(ArgumentError) { @view.render(:partial => "test/") }
    assert_equal "The partial name (test/) is not a valid Ruby identifier; " +
      "make sure your partial name starts with a letter or underscore, " +
      "and is followed by any combinations of letters, numbers, or underscores.", e.message
  end

  def test_render_partial_with_incompatible_object
    e = assert_raises(ArgumentError) { @view.render(:partial => nil) }
    assert_equal "'#{nil.inspect}' is not an ActiveModel-compatible object that returns a valid partial path.", e.message
  end

  def test_render_partial_with_errors
    e = assert_raises(ActionView::Template::Error) { @view.render(:partial => "test/raise") }
    assert_match %r!method.*doesnt_exist!, e.message
    assert_equal "", e.sub_template_message
    assert_equal "1", e.line_number
    assert_equal "1: <%= doesnt_exist %>", e.annoted_source_code.strip
    assert_equal File.expand_path("#{FIXTURE_LOAD_PATH}/test/_raise.html.erb"), e.file_name
  end

  def test_render_sub_template_with_errors
    e = assert_raises(ActionView::Template::Error) { @view.render(:template => "test/sub_template_raise") }
    assert_match %r!method.*doesnt_exist!, e.message
    assert_equal "Trace of template inclusion: #{File.expand_path("#{FIXTURE_LOAD_PATH}/test/sub_template_raise.html.erb")}", e.sub_template_message
    assert_equal "1", e.line_number
    assert_equal File.expand_path("#{FIXTURE_LOAD_PATH}/test/_raise.html.erb"), e.file_name
  end

  def test_render_file_with_errors
    e = assert_raises(ActionView::Template::Error) { @view.render(:file => File.expand_path("test/_raise", FIXTURE_LOAD_PATH)) }
    assert_match %r!method.*doesnt_exist!, e.message
    assert_equal "", e.sub_template_message
    assert_equal "1", e.line_number
    assert_equal "1: <%= doesnt_exist %>", e.annoted_source_code.strip
    assert_equal File.expand_path("#{FIXTURE_LOAD_PATH}/test/_raise.html.erb"), e.file_name
  end

  def test_render_object
    assert_equal "Hello: david", @view.render(:partial => "test/customer", :object => Customer.new("david"))
  end

  def test_render_object_with_array
    assert_equal "[1, 2, 3]", @view.render(:partial => "test/object_inspector", :object => [1, 2, 3])
  end

  def test_render_partial_collection
    assert_equal "Hello: davidHello: mary", @view.render(:partial => "test/customer", :collection => [ Customer.new("david"), Customer.new("mary") ])
  end

  def test_render_partial_collection_as_by_string
    assert_equal "david david davidmary mary mary",
      @view.render(:partial => "test/customer_with_var", :collection => [ Customer.new("david"), Customer.new("mary") ], :as => 'customer')
  end

  def test_render_partial_collection_as_by_symbol
    assert_equal "david david davidmary mary mary",
      @view.render(:partial => "test/customer_with_var", :collection => [ Customer.new("david"), Customer.new("mary") ], :as => :customer)
  end

  def test_render_partial_collection_without_as
    assert_equal "local_inspector,local_inspector_counter",
      @view.render(:partial => "test/local_inspector", :collection => [ Customer.new("mary") ])
  end

  def test_render_partial_with_empty_collection_should_return_nil
    assert_nil @view.render(:partial => "test/customer", :collection => [])
  end

  def test_render_partial_with_nil_collection_should_return_nil
    assert_nil @view.render(:partial => "test/customer", :collection => nil)
  end

  def test_render_partial_with_nil_values_in_collection
    assert_equal "Hello: davidHello: Anonymous", @view.render(:partial => "test/customer", :collection => [ Customer.new("david"), nil ])
  end

  def test_render_partial_with_empty_array_should_return_nil
    assert_nil @view.render(:partial => [])
  end

  def test_render_partial_using_string
    assert_equal "Hello: Anonymous", @controller_view.render('customer')
  end

  def test_render_partial_with_locals_using_string
    assert_equal "Hola: david", @controller_view.render('customer_greeting', :greeting => 'Hola', :customer_greeting => Customer.new("david"))
  end

  def test_render_partial_using_object
    assert_equal "Hello: lifo",
      @controller_view.render(Customer.new("lifo"), :greeting => "Hello")
  end

  def test_render_partial_using_collection
    customers = [ Customer.new("Amazon"), Customer.new("Yahoo") ]
    assert_equal "Hello: AmazonHello: Yahoo",
      @controller_view.render(customers, :greeting => "Hello")
  end

  class CustomerWithDeprecatedPartialPath
    attr_reader :name

    def self.model_name
      Struct.new(:partial_path).new("customers/customer")
    end

    def initialize(name)
      @name = name
    end
  end

  def test_render_partial_using_object_with_deprecated_partial_path
    assert_deprecated(/#model_name.*#partial_path.*#to_partial_path/) do
      assert_equal "Hello: nertzy",
        @controller_view.render(CustomerWithDeprecatedPartialPath.new("nertzy"), :greeting => "Hello")
    end
  end

  def test_render_partial_using_collection_with_deprecated_partial_path
    assert_deprecated(/#model_name.*#partial_path.*#to_partial_path/) do
      customers = [
        CustomerWithDeprecatedPartialPath.new("nertzy"),
        CustomerWithDeprecatedPartialPath.new("peeja")
      ]
      assert_equal "Hello: nertzyHello: peeja",
        @controller_view.render(customers, :greeting => "Hello")
    end
  end

  # TODO: The reason for this test is unclear, improve documentation
  def test_render_partial_and_fallback_to_layout
    assert_equal "Before (Josh)\n\nAfter", @view.render(:partial => "test/layout_for_partial", :locals => { :name => "Josh" })
  end

  # TODO: The reason for this test is unclear, improve documentation
  def test_render_missing_xml_partial_and_raise_missing_template
    @view.formats = [:xml]
    assert_raises(ActionView::MissingTemplate) { @view.render(:partial => "test/layout_for_partial") }
  ensure
    @view.formats = nil
  end

  def test_render_layout_with_block_and_other_partial_inside
    render = @view.render(:layout => "test/layout_with_partial_and_yield") { "Yield!" }
    assert_equal "Before\npartial html\nYield!\nAfter\n", render
  end

  def test_render_inline
    assert_equal "Hello, World!", @view.render(:inline => "Hello, World!")
  end

  def test_render_inline_with_locals
    assert_equal "Hello, Josh!", @view.render(:inline => "Hello, <%= name %>!", :locals => { :name => "Josh" })
  end

  def test_render_fallbacks_to_erb_for_unknown_types
    assert_equal "Hello, World!", @view.render(:inline => "Hello, World!", :type => :bar)
  end

  CustomHandler = lambda do |template|
    "@output_buffer = ''\n" +
      "@output_buffer << 'source: #{template.source.inspect}'\n"
  end

  def test_render_inline_with_render_from_to_proc
    ActionView::Template.register_template_handler :ruby_handler, :source.to_proc
    assert_equal '3', @view.render(:inline => "(1 + 2).to_s", :type => :ruby_handler)
  end

  def test_render_inline_with_compilable_custom_type
    ActionView::Template.register_template_handler :foo, CustomHandler
    assert_equal 'source: "Hello, World!"', @view.render(:inline => "Hello, World!", :type => :foo)
  end

  def test_render_inline_with_locals_and_compilable_custom_type
    ActionView::Template.register_template_handler :foo, CustomHandler
    assert_equal 'source: "Hello, <%= name %>!"', @view.render(:inline => "Hello, <%= name %>!", :locals => { :name => "Josh" }, :type => :foo)
  end
  
  def test_render_knows_about_types_registered_when_extensions_are_checked_earlier_in_initialization
    ActionView::Template::Handlers.extensions
    ActionView::Template.register_template_handler :foo, CustomHandler
    assert ActionView::Template::Handlers.extensions.include?(:foo)
  end

  def test_render_ignores_templates_with_malformed_template_handlers
    ActiveSupport::Deprecation.silence do
      %w(malformed malformed.erb malformed.html.erb malformed.en.html.erb).each do |name|
        assert_raises(ActionView::MissingTemplate) { @view.render(:file => "test/malformed/#{name}") }
      end
    end
  end

  def test_render_with_layout
    assert_equal %(<title></title>\nHello world!\n),
      @view.render(:file => "test/hello_world", :layout => "layouts/yield")
  end

  def test_render_with_layout_which_has_render_inline
    assert_equal %(welcome\nHello world!\n),
      @view.render(:file => "test/hello_world", :layout => "layouts/yield_with_render_inline_inside")
  end

  def test_render_with_layout_which_renders_another_partial
    assert_equal %(partial html\nHello world!\n),
      @view.render(:file => "test/hello_world", :layout => "layouts/yield_with_render_partial_inside")
  end

  def test_render_layout_with_block_and_yield
    assert_equal %(Content from block!\n),
      @view.render(:layout => "layouts/yield_only") { "Content from block!" }
  end

  def test_render_layout_with_block_and_yield_with_params
    assert_equal %(Yield! Content from block!\n),
      @view.render(:layout => "layouts/yield_with_params") { |param| "#{param} Content from block!" }
  end

  def test_render_layout_with_block_which_renders_another_partial_and_yields
    assert_equal %(partial html\nContent from block!\n),
      @view.render(:layout => "layouts/partial_and_yield") { "Content from block!" }
  end

  def test_render_partial_and_layout_without_block_with_locals
    assert_equal %(Before (Foo!)\npartial html\nAfter),
      @view.render(:partial => 'test/partial', :layout => 'test/layout_for_partial', :locals => { :name => 'Foo!'})
  end

  def test_render_partial_and_layout_without_block_with_locals_and_rendering_another_partial
    assert_equal %(Before (Foo!)\npartial html\npartial with partial\n\nAfter),
      @view.render(:partial => 'test/partial_with_partial', :layout => 'test/layout_for_partial', :locals => { :name => 'Foo!'})
  end

  def test_render_layout_with_a_nested_render_layout_call
    assert_equal %(Before (Foo!)\nBefore (Bar!)\npartial html\nAfter\npartial with layout\n\nAfter),
      @view.render(:partial => 'test/partial_with_layout', :layout => 'test/layout_for_partial', :locals => { :name => 'Foo!'})
  end

  def test_render_layout_with_a_nested_render_layout_call_using_block_with_render_partial
    assert_equal %(Before (Foo!)\nBefore (Bar!)\n\n  partial html\n\nAfterpartial with layout\n\nAfter),
      @view.render(:partial => 'test/partial_with_layout_block_partial', :layout => 'test/layout_for_partial', :locals => { :name => 'Foo!'})
  end

  def test_render_layout_with_a_nested_render_layout_call_using_block_with_render_content
    assert_equal %(Before (Foo!)\nBefore (Bar!)\n\n  Content from inside layout!\n\nAfterpartial with layout\n\nAfter),
      @view.render(:partial => 'test/partial_with_layout_block_content', :layout => 'test/layout_for_partial', :locals => { :name => 'Foo!'})
  end

  def test_render_with_nested_layout
    assert_equal %(<title>title</title>\n\n<div id="column">column</div>\n<div id="content">content</div>\n),
      @view.render(:file => "test/nested_layout", :layout => "layouts/yield")
  end

  def test_render_with_file_in_layout
    assert_equal %(\n<title>title</title>\n\n),
      @view.render(:file => "test/layout_render_file")
  end

  def test_render_layout_with_object
    assert_equal %(<title>David</title>),
      @view.render(:file => "test/layout_render_object")
  end
end

class CachedViewRenderTest < ActiveSupport::TestCase
  include RenderTestCases

  # Ensure view path cache is primed
  def setup
    view_paths = ActionController::Base.view_paths
    assert_equal ActionView::OptimizedFileSystemResolver, view_paths.first.class
    setup_view(view_paths)
  end

  def teardown
    GC.start
  end
end

class LazyViewRenderTest < ActiveSupport::TestCase
  include RenderTestCases

  # Test the same thing as above, but make sure the view path
  # is not eager loaded
  def setup
    path = ActionView::FileSystemResolver.new(FIXTURE_LOAD_PATH)
    view_paths = ActionView::PathSet.new([path])
    assert_equal ActionView::FileSystemResolver.new(FIXTURE_LOAD_PATH), view_paths.first
    setup_view(view_paths)
  end

  def teardown
    GC.start
  end

  if '1.9'.respond_to?(:force_encoding)
    def test_render_utf8_template_with_magic_comment
      with_external_encoding Encoding::ASCII_8BIT do
        result = @view.render(:file => "test/utf8_magic", :formats => [:html], :layouts => "layouts/yield")
        assert_equal Encoding::UTF_8, result.encoding
        assert_equal "\nРусский \nтекст\n\nUTF-8\nUTF-8\nUTF-8\n", result
      end
    end

    def test_render_utf8_template_with_default_external_encoding
      with_external_encoding Encoding::UTF_8 do
        result = @view.render(:file => "test/utf8", :formats => [:html], :layouts => "layouts/yield")
        assert_equal Encoding::UTF_8, result.encoding
        assert_equal "Русский текст\n\nUTF-8\nUTF-8\nUTF-8\n", result
      end
    end

    def test_render_utf8_template_with_incompatible_external_encoding
      with_external_encoding Encoding::SHIFT_JIS do
        e = assert_raises(ActionView::Template::Error) { @view.render(:file => "test/utf8", :formats => [:html], :layouts => "layouts/yield") }
        assert_match 'Your template was not saved as valid Shift_JIS', e.original_exception.message
      end
    end

    def test_render_utf8_template_with_partial_with_incompatible_encoding
      with_external_encoding Encoding::SHIFT_JIS do
        e = assert_raises(ActionView::Template::Error) { @view.render(:file => "test/utf8_magic_with_bare_partial", :formats => [:html], :layouts => "layouts/yield") }
        assert_match 'Your template was not saved as valid Shift_JIS', e.original_exception.message
      end
    end

    def with_external_encoding(encoding)
      old = Encoding.default_external
      silence_warnings { Encoding.default_external = encoding }
      yield
    ensure
      silence_warnings { Encoding.default_external = old }
    end
  end
end
