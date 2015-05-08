class HomeUserSerializer < ActiveModel::Serializer
  attributes :id, :name, :first_name, :display_phone_number, :phone_number, :booking_count, :avatar, :role, :role_cd, :notification_settings, :training, :earnings, :unpaid

  has_many :payments
  has_one  :contractor_profile
end
