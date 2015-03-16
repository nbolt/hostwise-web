module ApplicationHelper
  def first_property?
    controller.controller_name == 'properties' && controller.action_name == 'first'
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
    return class_name
  end
end
