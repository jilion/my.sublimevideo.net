# coding: utf-8
class AddonPlanExhibit < DisplayCase::Exhibit

  def self.applicable_to?(object, context)
    object.class.name == 'AddonPlan'
  end

  def kind_for_email
    'add-on'
  end

  def billable_entity_name_for_addon_page
    addon.name
  end

  def p_param_for_addon_page
    name
  end

  def eql?(other)
    (self.class == other.class) && (self.to_model == other.to_model)
  end
  alias :== eql?

end
