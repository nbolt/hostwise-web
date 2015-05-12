class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :booking_count
end
