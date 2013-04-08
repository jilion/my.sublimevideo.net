RSpec::Matchers.define :create_an_addon_activity do |*args|
  match_for_should do |block|
    addon_activities_count_before = Addons::AddonActivity.count
    block.call
    @new_addon_activities = Addons::AddonActivity.count - addon_activities_count_before
    @last_addon_activity = Addons::AddonActivity.last

    (@new_addon_activities == 1) &&
    (!@state || (@last_addon_activity.state == @state)) &&
    (!@addonship_id || (@last_addon_activity.addonship_id == @addonship_id))
  end

  chain :in_state do |state|
    @state = state
  end

  chain :with_addonship_id do |addonship_id|
    @addonship_id = addonship_id
  end

  failure_message_for_should do |x|
    text = "expected 1 new Addons::AddonActivity in state #{@state}"
    text += " and with addonship_id ##{@addonship_id}" if @addonship_id
    text += ", but got "
    if @last_addon_activity
      text += "#{@new_addon_activities} new Addons::AddonActivity and the last one is in "
      text += "state #{@last_addon_activity.state}"
      text += " with addonship_id ##{@last_addon_activity.id}" if @addonship_id
    else
      text += "#{@new_addon_activities} new Addons::AddonActivity"
    end
    text
  end
end
