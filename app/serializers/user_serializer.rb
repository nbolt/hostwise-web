class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :display_phone_number, :booking_count

  has_many :payouts
end
