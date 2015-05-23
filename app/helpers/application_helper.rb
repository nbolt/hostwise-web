module ApplicationHelper
  def first_property?
    controller.controller_name == 'properties' && controller.action_name == 'first'
  end

  def property?
    controller.controller_name == 'properties' && controller.action_name == 'show'
  end

  def property_list?
    controller.controller_name == 'home' && controller.action_name == 'index'
  end

  def linens_and_towels?
    controller.controller_name == 'home' && controller.action_name == 'linenandtowel'
  end

  def pricing?
    controller.controller_name == 'home' && controller.action_name == 'pricing'
  end

  def faq?
    controller.controller_name == 'home' && controller.action_name == 'faq'
  end

  def contact?
    controller.controller_name == 'home' && controller.action_name == 'contact'
  end

  def quiz?
    controller.controller_name == 'quiz' && controller.action_name == 'index'
  end

  def body_class
    class_name = 'grey'
    class_name = 'first-property-body' if first_property?
    class_name = 'pricing-body' if pricing?
    class_name = 'faq-body' if faq?
    class_name = 'contact-body' if contact?
    class_name = 'quiz-body' if quiz?
    class_name = 'property-body' if property?
    class_name = 'property-list-body' if logged_in? && current_user.role == :host && property_list?
    class_name = 'linen-program-body' if linens_and_towels?
    return class_name
  end
end
