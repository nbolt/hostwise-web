class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :first_name, :display_phone_number, :booking_count, :avatar, :role, :notification_settings

  has_many :payouts
end
