require 'abstract_unit'
require 'active_support/core_ext/logger'
require 'active_support/tagged_logging'

class TaggedLoggingTest < ActiveSupport::TestCase
  class MyLogger < ::Logger
    def flush(*)
      info "[FLUSHED]"
    end
  end

  setup do
    @output = StringIO.new
    @logger = ActiveSupport::TaggedLogging.new(MyLogger.new(@output))
  end

  test "tagged once" do
    @logger.tagged("BCX") { @logger.info "Funky time" }
    assert_equal "[BCX] Funky time\n", @output.string
  end
  
  test "tagged twice" do
    @logger.tagged("BCX") { @logger.tagged("Jason") { @logger.info "Funky time" } }
    assert_equal "[BCX] [Jason] Funky time\n", @output.string
  end

  test "tagged thrice at once" do
    @logger.tagged("BCX", "Jason", "New") { @logger.info "Funky time" }
    assert_equal "[BCX] [Jason] [New] Funky time\n", @output.string
  end

  test "tagged once with blank and nil" do
    @logger.tagged(nil, "", "New") { @logger.info "Funky time" }
    assert_equal "[New] Funky time\n", @output.string
  end

  test "keeps each tag in their own thread" do
    @logger.tagged("BCX") do
      Thread.new do
        @logger.tagged("OMG") { @logger.info "Cool story bro" }
      end.join
      @logger.info "Funky time"
    end
    assert_equal "[OMG] Cool story bro\n[BCX] Funky time\n", @output.string
  end

  test "cleans up the taggings on flush" do
    @logger.tagged("BCX") do
      Thread.new do
        @logger.tagged("OMG") do
          @logger.flush
          @logger.info "Cool story bro"
        end
      end.join
    end
    assert_equal "[FLUSHED]\nCool story bro\n", @output.string
  end

  test "mixed levels of tagging" do
    @logger.tagged("BCX") do
      @logger.tagged("Jason") { @logger.info "Funky time" }
      @logger.info "Junky time!"
    end

    assert_equal "[BCX] [Jason] Funky time\n[BCX] Junky time!\n", @output.string
  end

  test "silence" do
    assert_deprecated do
      assert_nothing_raised { @logger.silence {} }
    end
  end

  test "calls block" do
    @logger.tagged("BCX") do
      @logger.info { "Funky town" }
    end
    assert_equal "[BCX] Funky town\n", @output.string
  end

end
