require 'abstract_unit'
require 'test/unit'
require 'active_support/descendants_tracker'
require 'active_support/dependencies'
require 'descendants_tracker_test_cases'

class DescendantsTrackerWithAutoloadingTest < Test::Unit::TestCase
  include DescendantsTrackerTestCases

  def test_clear_with_autoloaded_parent_children_and_granchildren
    mark_as_autoloaded(*ALL) do
      ActiveSupport::DescendantsTracker.clear
      ALL.each do |k|
        assert ActiveSupport::DescendantsTracker.descendants(k).empty?
      end
    end
  end

  def test_clear_with_autoloaded_children_and_granchildren
    mark_as_autoloaded Child1, Grandchild1, Grandchild2 do
      ActiveSupport::DescendantsTracker.clear
      assert_equal [Child2], Parent.descendants
      assert_equal [], Child2.descendants
    end
  end

  def test_clear_with_autoloaded_granchildren
    mark_as_autoloaded Grandchild1, Grandchild2 do
      ActiveSupport::DescendantsTracker.clear
      assert_equal [Child1, Child2], Parent.descendants
      assert_equal [], Child1.descendants
      assert_equal [], Child2.descendants
    end
  end
end