module SorceryHelper
  extend Sorcery::Model::Submodules::UserActivation::InstanceMethods

  def self.included(base)
    base.send :extend, Sorcery::Model::Submodules::UserActivation::InstanceMethods
  end

  def deactivate!
    config = sorcery_config
    self.send(:"#{config.activation_state_attribute_name}=", 'deactivated')
    save!(validate: false) # don't run validations
  end

  def reactivate!
    config = sorcery_config
    self.send(:"#{config.activation_state_attribute_name}=", 'active')
    save!(validate: false) # don't run validations
  end
end
