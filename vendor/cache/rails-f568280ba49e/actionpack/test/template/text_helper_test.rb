# encoding: utf-8
require 'abstract_unit'
require 'testing_sandbox'

class TextHelperTest < ActionView::TestCase
  tests ActionView::Helpers::TextHelper
  include TestingSandbox

  def setup
    super
    # This simulates the fact that instance variables are reset every time
    # a view is rendered.  The cycle helper depends on this behavior.
    @_cycles = nil if (defined? @_cycles)
  end

  def test_concat
    self.output_buffer = 'foo'
    assert_equal 'foobar', concat('bar')
    assert_equal 'foobar', output_buffer
  end

  def test_simple_format_should_be_html_safe
    assert simple_format("<b> test with html tags </b>").html_safe?
  end

  def test_simple_format
    assert_equal "<p></p>", simple_format(nil)

    assert_equal "<p>crazy\n<br /> cross\n<br /> platform linebreaks</p>", simple_format("crazy\r\n cross\r platform linebreaks")
    assert_equal "<p>A paragraph</p>\n\n<p>and another one!</p>", simple_format("A paragraph\n\nand another one!")
    assert_equal "<p>A paragraph\n<br /> With a newline</p>", simple_format("A paragraph\n With a newline")

    text = "A\nB\nC\nD".freeze
    assert_equal "<p>A\n<br />B\n<br />C\n<br />D</p>", simple_format(text)

    text = "A\r\n  \nB\n\n\r\n\t\nC\nD".freeze
    assert_equal "<p>A\n<br />  \n<br />B</p>\n\n<p>\t\n<br />C\n<br />D</p>", simple_format(text)

    assert_equal %q(<p class="test">This is a classy test</p>), simple_format("This is a classy test", :class => 'test')
    assert_equal %Q(<p class="test">para 1</p>\n\n<p class="test">para 2</p>), simple_format("para 1\n\npara 2", :class => 'test')
  end

  def test_simple_format_should_sanitize_input_when_sanitize_option_is_not_false
    assert_equal "<p><b> test with unsafe string </b></p>", simple_format("<b> test with unsafe string </b><script>code!</script>")
  end

  def test_simple_format_should_not_sanitize_input_when_sanitize_option_is_false
    assert_equal "<p><b> test with unsafe string </b><script>code!</script></p>", simple_format("<b> test with unsafe string </b><script>code!</script>", {}, :sanitize => false)
  end

  def test_simple_format_should_not_change_the_text_passed
    text = "<b>Ok</b><script>code!</script>"
    text_clone = text.dup
    simple_format(text)
    assert_equal text_clone, text
  end

  def test_truncate_should_not_be_html_safe
    assert !truncate("Hello World!", :length => 12).html_safe?
  end

  def test_truncate
    assert_equal "Hello World!", truncate("Hello World!", :length => 12)
    assert_equal "Hello Wor...", truncate("Hello World!!", :length => 12)
  end

  def test_truncate_should_not_escape_input
    assert_equal "Hello <sc...", truncate("Hello <script>code!</script>World!!", :length => 12)
  end

  def test_truncate_should_use_default_length_of_30
    str = "This is a string that will go longer then the default truncate length of 30"
    assert_equal str[0...27] + "...", truncate(str)
  end

  def test_truncate_with_options_hash
    assert_equal "This is a string that wil[...]", truncate("This is a string that will go longer then the default truncate length of 30", :omission => "[...]")
    assert_equal "Hello W...", truncate("Hello World!", :length => 10)
    assert_equal "Hello[...]", truncate("Hello World!", :omission => "[...]", :length => 10)
    assert_equal "Hello[...]", truncate("Hello Big World!", :omission => "[...]", :length => 13, :separator => ' ')
    assert_equal "Hello Big[...]", truncate("Hello Big World!", :omission => "[...]", :length => 14, :separator => ' ')
    assert_equal "Hello Big[...]", truncate("Hello Big World!", :omission => "[...]", :length => 15, :separator => ' ')
  end

  if RUBY_VERSION < '1.9.0'
    def test_truncate_multibyte
      with_kcode 'none' do
        assert_equal "\354\225\210\353\205\225\355...", truncate("\354\225\210\353\205\225\355\225\230\354\204\270\354\232\224", :length => 10)
      end
      with_kcode 'u' do
        assert_equal "\354\225\204\353\246\254\353\236\221 \354\225\204\353\246\254 ...",
          truncate("\354\225\204\353\246\254\353\236\221 \354\225\204\353\246\254 \354\225\204\353\235\274\353\246\254\354\230\244", :length => 10)
      end
    end
  else
    def test_truncate_multibyte
      # .mb_chars always returns a UTF-8 String.
      # assert_equal "\354\225\210\353\205\225\355...",
      #   truncate("\354\225\210\353\205\225\355\225\230\354\204\270\354\232\224", :length => 10)

      assert_equal "\354\225\204\353\246\254\353\236\221 \354\225\204\353\246\254 ...".force_encoding('UTF-8'),
        truncate("\354\225\204\353\246\254\353\236\221 \354\225\204\353\246\254 \354\225\204\353\235\274\353\246\254\354\230\244".force_encoding('UTF-8'), :length => 10)
    end
  end

  def test_highlight_should_be_html_safe
    assert highlight("This is a beautiful morning", "beautiful").html_safe?
  end

  def test_highlight
    assert_equal(
      "This is a <strong class=\"highlight\">beautiful</strong> morning",
      highlight("This is a beautiful morning", "beautiful")
    )

    assert_equal(
      "This is a <strong class=\"highlight\">beautiful</strong> morning, but also a <strong class=\"highlight\">beautiful</strong> day",
      highlight("This is a beautiful morning, but also a beautiful day", "beautiful")
    )

    assert_equal(
      "This is a <b>beautiful</b> morning, but also a <b>beautiful</b> day",
      highlight("This is a beautiful morning, but also a beautiful day", "beautiful", :highlighter => '<b>\1</b>')
    )

    assert_equal(
      "This text is not changed because we supplied an empty phrase",
      highlight("This text is not changed because we supplied an empty phrase", nil)
    )

    assert_equal '   ', highlight('   ', 'blank text is returned verbatim')
  end

  def test_highlight_old_api_is_depcrecated
    assert_deprecated("Calling highlight with a highlighter as an argument is deprecated. Please call with :highlighter => '<mark>\\1</mark>' instead.") do
      highlight("This is a beautiful morning", "beautiful", '<mark>\1</mark>')
    end
  end

  def test_highlight_should_sanitize_input
    assert_equal(
      "This is a <strong class=\"highlight\">beautiful</strong> morning",
      highlight("This is a beautiful morning<script>code!</script>", "beautiful")
    )
  end

  def test_highlight_should_not_sanitize_if_sanitize_option_if_false
    assert_equal(
      "This is a <strong class=\"highlight\">beautiful</strong> morning<script>code!</script>",
      highlight("This is a beautiful morning<script>code!</script>", "beautiful", :sanitize => false)
    )
  end

  def test_highlight_with_regexp
    assert_equal(
      "This is a <strong class=\"highlight\">beautiful!</strong> morning",
      highlight("This is a beautiful! morning", "beautiful!")
    )

    assert_equal(
      "This is a <strong class=\"highlight\">beautiful! morning</strong>",
      highlight("This is a beautiful! morning", "beautiful! morning")
    )

    assert_equal(
      "This is a <strong class=\"highlight\">beautiful? morning</strong>",
      highlight("This is a beautiful? morning", "beautiful? morning")
    )
  end

  def test_highlight_with_multiple_phrases_in_one_pass
    assert_equal %(<em>wow</em> <em>em</em>), highlight('wow em', %w(wow em), :highlighter => '<em>\1</em>')
  end

  def test_highlight_with_html
    assert_equal(
      "<p>This is a <strong class=\"highlight\">beautiful</strong> morning, but also a <strong class=\"highlight\">beautiful</strong> day</p>",
      highlight("<p>This is a beautiful morning, but also a beautiful day</p>", "beautiful")
    )
    assert_equal(
      "<p>This is a <em><strong class=\"highlight\">beautiful</strong></em> morning, but also a <strong class=\"highlight\">beautiful</strong> day</p>",
      highlight("<p>This is a <em>beautiful</em> morning, but also a beautiful day</p>", "beautiful")
    )
    assert_equal(
      "<p>This is a <em class=\"error\"><strong class=\"highlight\">beautiful</strong></em> morning, but also a <strong class=\"highlight\">beautiful</strong> <span class=\"last\">day</span></p>",
      highlight("<p>This is a <em class=\"error\">beautiful</em> morning, but also a beautiful <span class=\"last\">day</span></p>", "beautiful")
    )
    assert_equal(
      "<p class=\"beautiful\">This is a <strong class=\"highlight\">beautiful</strong> morning, but also a <strong class=\"highlight\">beautiful</strong> day</p>",
      highlight("<p class=\"beautiful\">This is a beautiful morning, but also a beautiful day</p>", "beautiful")
    )
    assert_equal(
      "<p>This is a <strong class=\"highlight\">beautiful</strong> <a href=\"http://example.com/beautiful#top?what=beautiful%20morning&amp;when=now+then\">morning</a>, but also a <strong class=\"highlight\">beautiful</strong> day</p>",
      highlight("<p>This is a beautiful <a href=\"http://example.com/beautiful\#top?what=beautiful%20morning&when=now+then\">morning</a>, but also a beautiful day</p>", "beautiful")
    )
    assert_equal(
      "<div>abc <b>div</b></div>",
      highlight("<div>abc div</div>", "div", :highlighter => '<b>\1</b>')
    )
  end

  def test_excerpt
    assert_equal("...is a beautiful morn...", excerpt("This is a beautiful morning", "beautiful", :radius => 5))
    assert_equal("This is a...", excerpt("This is a beautiful morning", "this", :radius => 5))
    assert_equal("...iful morning", excerpt("This is a beautiful morning", "morning", :radius => 5))
    assert_nil excerpt("This is a beautiful morning", "day")
  end

  def test_excerpt_old_api_is_depcrecated
    assert_deprecated("Calling excerpt with radius and omission as arguments is deprecated. Please call with :radius => 5 instead.") do
      excerpt("This is a beautiful morning", "morning", 5)
    end
    assert_deprecated("Calling excerpt with radius and omission as arguments is deprecated. Please call with :radius => 5, :omission => 'mor' instead.") do
      excerpt("This is a beautiful morning", "morning", 5, "mor")
    end
  end

  def test_excerpt_should_not_be_html_safe
    assert !excerpt('This is a beautiful! morning', 'beautiful', :radius => 5).html_safe?
  end

  def test_excerpt_in_borderline_cases
    assert_equal("", excerpt("", "", :radius => 0))
    assert_equal("a", excerpt("a", "a", :radius => 0))
    assert_equal("...b...", excerpt("abc", "b", :radius => 0))
    assert_equal("abc", excerpt("abc", "b", :radius => 1))
    assert_equal("abc...", excerpt("abcd", "b", :radius => 1))
    assert_equal("...abc", excerpt("zabc", "b", :radius => 1))
    assert_equal("...abc...", excerpt("zabcd", "b", :radius => 1))
    assert_equal("zabcd", excerpt("zabcd", "b", :radius => 2))

    # excerpt strips the resulting string before ap-/prepending excerpt_string.
    # whether this behavior is meaningful when excerpt_string is not to be
    # appended is questionable.
    assert_equal("zabcd", excerpt("  zabcd  ", "b", :radius => 4))
    assert_equal("...abc...", excerpt("z  abc  d", "b", :radius => 1))
  end

  def test_excerpt_with_regex
    assert_equal('...is a beautiful! mor...', excerpt('This is a beautiful! morning', 'beautiful', :radius => 5))
    assert_equal('...is a beautiful? mor...', excerpt('This is a beautiful? morning', 'beautiful', :radius => 5))
  end

  def test_excerpt_with_omission
    assert_equal("[...]is a beautiful morn[...]", excerpt("This is a beautiful morning", "beautiful", :omission => "[...]",:radius => 5))
    assert_equal(
      "This is the ultimate supercalifragilisticexpialidoceous very looooooooooooooooooong looooooooooooong beautiful morning with amazing sunshine and awesome tempera[...]",
      excerpt("This is the ultimate supercalifragilisticexpialidoceous very looooooooooooooooooong looooooooooooong beautiful morning with amazing sunshine and awesome temperatures. So what are you gonna do about it?", "very",
      :omission => "[...]")
    )
  end

  if RUBY_VERSION < '1.9'
    def test_excerpt_with_utf8
      with_kcode('u') do
        assert_equal("...\357\254\203ciency could not be...", excerpt("That's why e\357\254\203ciency could not be helped", 'could', :radius => 8))
      end
      with_kcode('none') do
        assert_equal("...\203ciency could not be...", excerpt("That's why e\357\254\203ciency could not be helped", 'could', :radius => 8))
      end
    end
  else
    def test_excerpt_with_utf8
      assert_equal("...\357\254\203ciency could not be...".force_encoding('UTF-8'), excerpt("That's why e\357\254\203ciency could not be helped".force_encoding('UTF-8'), 'could', :radius => 8))
      # .mb_chars always returns UTF-8, even in 1.9. This is not great, but it's how it works. Let's work this out.
      # assert_equal("...\203ciency could not be...", excerpt("That's why e\357\254\203ciency could not be helped".force_encoding("BINARY"), 'could', 8))
    end
  end

  def test_word_wrap
    assert_equal("my very very\nvery long\nstring", word_wrap("my very very very long string", :line_width => 15))
  end

  def test_word_wrap_old_api_is_depcrecated
    assert_deprecated("Calling word_wrap with line_width as an argument is deprecated. Please call with :line_width => 15 instead.") do
      word_wrap("my very very very long string", 15)
    end
  end

  def test_word_wrap_with_extra_newlines
    assert_equal("my very very\nvery long\nstring\n\nwith another\nline", word_wrap("my very very very long string\n\nwith another line", :line_width => 15))
  end

  def test_pluralization
    assert_equal("1 count", pluralize(1, "count"))
    assert_equal("2 counts", pluralize(2, "count"))
    assert_equal("1 count", pluralize('1', "count"))
    assert_equal("2 counts", pluralize('2', "count"))
    assert_equal("1,066 counts", pluralize('1,066', "count"))
    assert_equal("1.25 counts", pluralize('1.25', "count"))
    assert_equal("1.0 count", pluralize('1.0', "count"))
    assert_equal("1.00 count", pluralize('1.00', "count"))
    assert_equal("2 counters", pluralize(2, "count", "counters"))
    assert_equal("0 counters", pluralize(nil, "count", "counters"))
    assert_equal("2 people", pluralize(2, "person"))
    assert_equal("10 buffaloes", pluralize(10, "buffalo"))
    assert_equal("1 berry", pluralize(1, "berry"))
    assert_equal("12 berries", pluralize(12, "berry"))
  end

  def test_cycle_class
    value = Cycle.new("one", 2, "3")
    assert_equal("one", value.to_s)
    assert_equal("2", value.to_s)
    assert_equal("3", value.to_s)
    assert_equal("one", value.to_s)
    value.reset
    assert_equal("one", value.to_s)
    assert_equal("2", value.to_s)
    assert_equal("3", value.to_s)
  end

  def test_cycle_class_with_no_arguments
    assert_raise(ArgumentError) { Cycle.new }
  end

  def test_cycle
    assert_equal("one", cycle("one", 2, "3"))
    assert_equal("2", cycle("one", 2, "3"))
    assert_equal("3", cycle("one", 2, "3"))
    assert_equal("one", cycle("one", 2, "3"))
    assert_equal("2", cycle("one", 2, "3"))
    assert_equal("3", cycle("one", 2, "3"))
  end

  def test_cycle_with_no_arguments
    assert_raise(ArgumentError) { cycle }
  end

  def test_cycle_resets_with_new_values
    assert_equal("even", cycle("even", "odd"))
    assert_equal("odd", cycle("even", "odd"))
    assert_equal("even", cycle("even", "odd"))
    assert_equal("1", cycle(1, 2, 3))
    assert_equal("2", cycle(1, 2, 3))
    assert_equal("3", cycle(1, 2, 3))
    assert_equal("1", cycle(1, 2, 3))
  end

  def test_named_cycles
    assert_equal("1", cycle(1, 2, 3, :name => "numbers"))
    assert_equal("red", cycle("red", "blue", :name => "colors"))
    assert_equal("2", cycle(1, 2, 3, :name => "numbers"))
    assert_equal("blue", cycle("red", "blue", :name => "colors"))
    assert_equal("3", cycle(1, 2, 3, :name => "numbers"))
    assert_equal("red", cycle("red", "blue", :name => "colors"))
  end

  def test_current_cycle_with_default_name
    cycle("even","odd")
    assert_equal "even", current_cycle
    cycle("even","odd")
    assert_equal "odd", current_cycle
    cycle("even","odd")
    assert_equal "even", current_cycle
  end

  def test_current_cycle_with_named_cycles
    cycle("red", "blue", :name => "colors")
    assert_equal "red", current_cycle("colors")
    cycle("red", "blue", :name => "colors")
    assert_equal "blue", current_cycle("colors")
    cycle("red", "blue", :name => "colors")
    assert_equal "red", current_cycle("colors")
  end

  def test_current_cycle_safe_call
    assert_nothing_raised { current_cycle }
    assert_nothing_raised { current_cycle("colors") }
  end

  def test_current_cycle_with_more_than_two_names
    cycle(1,2,3)
    assert_equal "1", current_cycle
    cycle(1,2,3)
    assert_equal "2", current_cycle
    cycle(1,2,3)
    assert_equal "3", current_cycle
    cycle(1,2,3)
    assert_equal "1", current_cycle
  end

  def test_default_named_cycle
    assert_equal("1", cycle(1, 2, 3))
    assert_equal("2", cycle(1, 2, 3, :name => "default"))
    assert_equal("3", cycle(1, 2, 3))
  end

  def test_reset_cycle
    assert_equal("1", cycle(1, 2, 3))
    assert_equal("2", cycle(1, 2, 3))
    reset_cycle
    assert_equal("1", cycle(1, 2, 3))
  end

  def test_reset_unknown_cycle
    reset_cycle("colors")
  end

  def test_recet_named_cycle
    assert_equal("1", cycle(1, 2, 3, :name => "numbers"))
    assert_equal("red", cycle("red", "blue", :name => "colors"))
    reset_cycle("numbers")
    assert_equal("1", cycle(1, 2, 3, :name => "numbers"))
    assert_equal("blue", cycle("red", "blue", :name => "colors"))
    assert_equal("2", cycle(1, 2, 3, :name => "numbers"))
    assert_equal("red", cycle("red", "blue", :name => "colors"))
  end

  def test_cycle_no_instance_variable_clashes
    @cycles = %w{Specialized Fuji Giant}
    assert_equal("red", cycle("red", "blue"))
    assert_equal("blue", cycle("red", "blue"))
    assert_equal("red", cycle("red", "blue"))
    assert_equal(%w{Specialized Fuji Giant}, @cycles)
  end
end
