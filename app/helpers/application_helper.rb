module ApplicationHelper
  def first_property?
    controller.controller_name == 'properties' && controller.action_name == 'first'
  end
end
