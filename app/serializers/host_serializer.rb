class HostSerializer < ActiveModel::Serializer
  attributes :id, :name, :display_phone_number, :avatar

  has_many :properties, serializer: HostPropertySerializer
  has_many :comments, serializer: HostCommentSerializer
end
