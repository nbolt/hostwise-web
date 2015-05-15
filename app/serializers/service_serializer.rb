class ServiceSerializer < ActiveModel::Serializer
  attributes :id, :name, :display, :serializer_display
end
