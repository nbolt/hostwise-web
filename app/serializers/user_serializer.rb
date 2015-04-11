class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :display_phone_number

  has_many :properties, serializer: UserPropertySerializer
end
